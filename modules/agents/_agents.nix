{
  claudeCode = {
    deepseek = {
      enable = true;
      effortLevel = "max";
    };
    gpu.enable = false;
    qwen = {
      enable = true;
      smallModel = "qwen3_8_flash";
    };
    senseaudio.enable = false;
    stepfun = {
      enable = false;
      smallModel = "step_3_7_flash";
    };
    volces.enable = false;
  };
  claudeDesktop = {
    deepseek = {
      enable = true;
      default = true;
      profileId = "00000000-0000-4000-8000-00000000d335";
      models = [
        "ds_v4flash"
        "ds_v4pro"
      ];
    };
    gpu.enable = false;
    qwen.enable = false;
    senseaudio.enable = false;
    stepfun.enable = false;
    volces.enable = false;
  };
  codex = {
    deepseek = {
      enable = true;
      disableWebSearch = true;
      profile = "codex-ds";
    };
    gpu.enable = true;
    qwen.enable = true;
    senseaudio.enable = false;
    stepfun = {
      enable = false;
      disableWebSearch = true;
    };
    volces = {
      enable = false;
      profile = "codex-volce";
      reasoningSummaries = true;
    };
  };
  omp.deepseek = {
    enable = true;
    default = true;
  };
  omp.gpu.enable = true;
  omp.qwen.enable = true;
  omp.senseaudio.enable = false;
  omp.stepfun.enable = false;
  omp.volces.enable = false;
  pi = {
    deepseek = {
      enable = true;
      default = true;
    };
    gpu.enable = true;
    qwen = {
      enable = true;
      api = "openai-responses";
    };
    senseaudio.enable = false;
    stepfun.enable = false;
    volces = {
      enable = false;
      defaultModel = "glm_5_3";
    };
  };
  reasonix = {
    deepseek = {
      enable = true;
      default = true;
    };
    gpu.enable = false;
    qwen.enable = false;
    senseaudio.enable = false;
    stepfun.enable = false;
    volces.enable = false;
  };
}
