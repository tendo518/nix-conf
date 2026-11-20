# Local connection settings. Each exposed model is explicit; model facts come
# from the matching models.dev provider entry or local.nix.
{
  deepseek = {
    name = "DeepSeek";
    modelsDevProvider = "deepseek";
    # Pi/DSH use the DeepSeek wire dialect; OMP detects it from the endpoint.
    thinkingFormat = "deepseek";
    secret = "deepseek-api-key";
    defaultModel = "deepseek-flash";
    models = [
      "deepseek-flash"
      "deepseek-v4-pro"
    ];
    endpoints = {
      anthropic = "https://api.deepseek.com/anthropic";
      balance = "https://api.deepseek.com/user/balance";
      openai = "https://api.deepseek.com";
    };
  };
  gpu = {
    name = "GPU";
    # The local Qwen-compatible server uses the Qwen thinking toggle.
    thinkingFormat = "qwen";
    secret = "gpu-api-key";
    defaultModel = "qwen3.8-27b";
    endpoints.openai = "http://172.18.36.44:8000/v1";
    models = [
      "local/gpu-qwen3.8-27b"
    ];
  };
  openai = {
    name = "OpenAI";
    modelsDevProvider = "openai";
    secret = "openai-api-key";
    defaultModel = "gpt-6.2-sol";
    endpoints.openai = "https://api.openai.com/v1";
    models = [
      "gpt-6.2-sol"
      "gpt-6.2-astra"
      "gpt-6-luna"
    ];
  };
  qwen = {
    name = "Qwen Token Plan";
    modelsDevProvider = "alibaba-token-plan";
    # Chat Completions uses enable_thinking plus reasoning_effort.
    thinkingFormat = "qwen";
    secret = "qwen-tokenplan-api-key";
    defaultModel = "qwen3.8-max";
    endpoints = {
      anthropic = "https://token-plan.maas.qianwenaiapi.com/apps/anthropic";
      openai = "https://token-plan.maas.qianwenaiapi.com/compatible-mode/v1";
    };
    models = [
      "qwen3.8-max"
      "qwen3.8-flash"
      "glm-5.3"
      "deepseek-v4.1-flash"
      "deepseek-v4.1-flash-1017"
      "local/qwen4-max"
    ];
  };
  volces = {
    name = "Volcengine Coding Plan";
    modelsDevProvider = "volcengine-coding-plan";
    # GLM on Ark uses the Z.ai-style thinking object.
    thinkingFormat = "zai";
    secret = "volcengine-codingplan-api-key";
    defaultModel = "glm-5.3-flash";
    models = [
      "glm-5.3"
      "glm-5.3-flash"
    ];
    endpoints = {
      anthropic = "https://ark.cn-beijing.volces.com/api/coding";
      openai = "https://ark.cn-beijing.volces.com/api/coding/v3";
    };
  };
}
