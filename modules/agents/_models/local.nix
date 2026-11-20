# Explicit connection facts for services without a matching models.dev entry.
{
  "local/gpu-qwen3.8-27b" = {
    id = "qwen3.8-27b";
    name = "Qwen3.8 27B";
    description = "Qwen3.8 27B served by the local GPU endpoint.";
    reasoning = true;
    # https://docs.qwencloud.com/api-reference/chat/openai-chat
    reasoning_options = [
      {
        type = "effort";
        values = [
          "none"
          "low"
          "medium"
          "xhigh"
        ];
      }
    ];
    tool_call = true;
    modalities = {
      input = [
        "text"
        "image"
      ];
      output = [ "text" ];
    };
    limit = {
      context = 262144;
      output = 32768;
    };
  };

  "local/qwen4-max" = {
    id = "qwen4-max";
    name = "Qwen4 Max";
    description = "Qwen4 Max served by the Qwen Token Plan gateway.";
    reasoning = true;
    # https://www.alibabacloud.com/help/en/model-studio/qwen4-max
    reasoning_options = [
      {
        type = "effort";
        values = [
          "none"
          "low"
          "high"
          "xhigh"
        ];
      }
    ];
    tool_call = true;
    modalities = {
      input = [
        "text"
        "image"
        "video"
        "pdf"
      ];
      output = [ "text" ];
    };
    limit = {
      context = 1000000;
      output = 262144;
    };
  };

}
