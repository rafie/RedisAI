#include "backends/torch.h"
#include "tensor.h"
#include "util/alloc.h"
#include "util/arr_rm_alloc.h"
#include "torch_c.h"


RAI_Model *RAI_ModelCreateTorch(RAI_Backend backend, RAI_Device device,
                                const char *modeldef, size_t modellen,
                                RAI_Error *error) {
  DLDeviceType dl_device;
  switch (device) {
    case RAI_DEVICE_CPU:
      dl_device = kDLCPU;
      break;
    case RAI_DEVICE_GPU:
      dl_device = kDLGPU;
      break;
    default:
      RAI_SetError(error, RAI_EMODELCONFIGURE, "Error configuring model: unsupported device\n");
      return NULL;
  }

  char* error_descr = NULL;
  void* model = torchLoadModel(modeldef, modellen, dl_device, &error_descr);

  if (model == NULL) {
    RAI_SetError(error, RAI_EMODELCREATE, error_descr);
    free(error_descr);
    return NULL;
  }

  RAI_Model* ret = RedisModule_Calloc(1, sizeof(*ret));
  ret->model = model;
  ret->session = NULL;
  ret->backend = backend;
  ret->device = device;
  ret->inputs = NULL;
  ret->outputs = NULL;
  ret->refCount = 1;

  return ret;
}

void RAI_ModelFreeTorch(RAI_Model* model, RAI_Error *error) {
  torchDeallocContext(model->model);
}

int RAI_ModelRunTorch(RAI_ModelRunCtx* mctx, RAI_Error *error) {

  size_t ninputs = array_len(mctx->inputs);
  size_t noutputs = array_len(mctx->outputs);

  DLManagedTensor** inputs = RedisModule_Calloc(ninputs, sizeof(*inputs));
  DLManagedTensor** outputs = RedisModule_Calloc(noutputs, sizeof(*outputs));

  for (size_t i=0 ; i<ninputs; ++i) {
    inputs[i] = &mctx->inputs[i].tensor->tensor;
  }

  for (size_t i=0 ; i<noutputs; ++i) {
    outputs[i] = &mctx->outputs[i].tensor->tensor;
  }

  char* error_descr = NULL;
  torchRunModel(mctx->model->model,
                ninputs, inputs,
                noutputs, outputs, &error_descr);

  if (error_descr != NULL) {
    RAI_SetError(error, RAI_EMODELRUN, error_descr);
    free(error_descr);
    return 1;
  }

  for(size_t i=0 ; i<array_len(mctx->outputs) ; ++i) {
    if (outputs[i] == NULL) {
      RAI_SetError(error, RAI_EMODELRUN, "Model did not generate the expected number of outputs.");
      free(error_descr);
      return 1;
    }
    RAI_Tensor* output_tensor = RAI_TensorCreateFromDLTensor(outputs[i]);
    mctx->outputs[i].tensor = RAI_TensorGetShallowCopy(output_tensor);
    RAI_TensorFree(output_tensor);
  }

  return 0;
}

int RAI_ModelSerializeTorch(RAI_Model *model, char **buffer, size_t *len, RAI_Error *error) {
  char* error_descr = NULL;
  torchSerializeModel(model->model, buffer, len, &error_descr);

  if (*buffer == NULL) {
    RAI_SetError(error, RAI_EMODELSERIALIZE, error_descr);
    free(error_descr);
    return 1;
  }

  return 0;
}

RAI_Script *RAI_ScriptCreateTorch(RAI_Device device, const char *scriptdef, RAI_Error *error) {
  DLDeviceType dl_device;
  switch (device) {
    case RAI_DEVICE_CPU:
      dl_device = kDLCPU;
      break;
    case RAI_DEVICE_GPU:
      dl_device = kDLGPU;
      break;
    default:
      RAI_SetError(error, RAI_ESCRIPTCONFIGURE, "Error configuring script: unsupported device\n");
      break;
  }

  char* error_descr = NULL;
  void* script = torchCompileScript(scriptdef, dl_device, &error_descr);

  if (script == NULL) {
    RAI_SetError(error, RAI_ESCRIPTCREATE, error_descr);
    free(error_descr);
    return NULL;
  }

  RAI_Script* ret = RedisModule_Calloc(1, sizeof(*ret));
  ret->script = script;
  ret->scriptdef = RedisModule_Strdup(scriptdef);
  ret->device = device;
  ret->refCount = 1;

  return ret;
}

void RAI_ScriptFreeTorch(RAI_Script* script, RAI_Error* error) {

  torchDeallocContext(script->script);
  RedisModule_Free(script->scriptdef);
  RedisModule_Free(script);
}

int RAI_ScriptRunTorch(RAI_ScriptRunCtx* sctx, RAI_Error* error) {

  long nInputs = array_len(sctx->inputs);
  long nOutputs = array_len(sctx->outputs);

  DLManagedTensor* inputs[nInputs];
  DLManagedTensor* outputs[nOutputs];

  for (size_t i=0; i<nInputs; i++) {
    inputs[i] = &sctx->inputs[i].tensor->tensor;
  }

  for (size_t i=0; i<nOutputs; i++) {
    outputs[i] = &sctx->outputs[i].tensor->tensor;
  }

  char* error_descr = NULL;
  torchRunScript(sctx->script->script, sctx->fnname, nInputs, inputs, nOutputs, outputs, &error_descr);

  if (error_descr) {
    printf("F\n");
    RAI_SetError(error, RAI_ESCRIPTRUN, error_descr);
    free(error_descr);
    return 1;
  }

  for (size_t i=0; i<nOutputs; i++) {
    sctx->outputs[i].tensor = RAI_TensorCreateFromDLTensor(outputs[i]);
  }

  return 0;
}
