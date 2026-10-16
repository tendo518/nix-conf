{
  name = "GPU";
  secret = "gpu-api-key";
  defaultModel = "qwen3_8_27b";
  endpoints.openai = "http://172.18.36.44:8000/v1";
  agents = {
    codex = { };
    omp = { };
    pi = { };
  };
  models = {
    qwen3_8_27b = {
      id = "qwen3.8-27b";
      displayName = "Qwen3.8 27B";
      contextWindow = 240000;
      input = [
        "text"
        "image"
      ];
      thinking = {
        efforts = [
          "low"
          "medium"
          "high"
        ];
        default = "high";
      };
      codexSupportsOriginalImageDetail = true;
    };
  };
}
