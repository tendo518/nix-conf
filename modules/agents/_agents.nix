# Local agent policy. Omitted providers are disabled.
{
  claudeCode = {
    deepseek = {
      enable = true;
      effortLevel = "max";
    };
    qwen = {
      enable = true;
      smallModel = "qwen3_8_flash";
    };
  };
  claudeDesktop.deepseek = {
    enable = true;
    default = true;
    profileId = "00000000-0000-4000-8000-00000000d335";
    models = [
      "ds_v4flash"
      "ds_v4pro"
    ];
  };
  codex = {
    deepseek = {
      enable = true;
      profile = "codex-ds";
    };
    gpu.enable = true;
    openai = {
      enable = true;
      providerId = "openai-api";
    };
    qwen.enable = true;
  };
  dsh = {
    deepseek.enable = true;
    openai = {
      enable = true;
      api = "openai-responses";
    };
    qwen.enable = true;
  };
  omp = {
    deepseek = {
      enable = true;
      default = true;
    };
    gpu.enable = true;
    openai = {
      enable = true;
      api = "openai-responses";
    };
    qwen.enable = true;
  };
  pi = {
    deepseek = {
      enable = true;
      default = true;
    };
    gpu.enable = true;
    openai = {
      enable = true;
      api = "openai-responses";
    };
    qwen = {
      enable = true;
      api = "openai-responses";
    };
  };
  reasonix.deepseek = {
    enable = true;
    default = true;
  };
}
