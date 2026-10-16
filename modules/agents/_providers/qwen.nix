{
  name = "Qwen Token Plan";
  secret = "qwen-tokenplan-api-key";
  defaultModel = "qwen3_8_max";
  endpoints = {
    anthropic = "https://token-plan.maas.qianwenaiapi.com/apps/anthropic";
    openai = "https://token-plan.maas.qianwenaiapi.com/compatible-mode/v1";
  };
  codexSupportsParallelToolCalls = false;
  agents = {
    claudeCode.smallModel = "qwen3_8_flash";
    codex = { };
    omp = { };
    pi = { };
  };
  models = {
    qwen3_8_max = {
      id = "qwen3.8-max";
      displayName = "Qwen3.8 Max";
      contextWindow = 1000000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "xhigh"
        ];
        default = "xhigh";
      };
      claudeBehavesAs = "claude-opus-5-5";
      codexPriority = 1;
      codexSupportsOriginalImageDetail = true;
    };
    qwen3_8_flash = {
      id = "qwen3.8-flash";
      displayName = "Qwen3.8 Flash";
      contextWindow = 1000000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "xhigh"
        ];
        default = "xhigh";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexPriority = 2;
      codexSupportsOriginalImageDetail = true;
    };
    glm_5_3 = {
      id = "glm-5.3";
      displayName = "GLM 5.3";
      contextWindow = 1000000;
      input = [ "text" ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-opus-5-5";
      codexPriority = 6;
    };
    ds_v4_1flash = {
      id = "deepseek-v4.1-flash";
      displayName = "DeepSeek-V4.1-Flash";
      contextWindow = 1000000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
          "xhigh"
        ];
        default = "high";
      };
      claudeBehavesAs = "claude-sonnet-5";
      codexPriority = 8;
      codexSupportsOriginalImageDetail = true;
    };
  };
}
