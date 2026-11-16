# Explicit declarations for models absent from models.dev/models.json.
{
  "local/step-router-v1" = {
    name = "Step Router V1";
    description = "Routes between deepseek-v4-pro and step-3.7-flash.";
    reasoning = true;
    tool_call = true;
    modalities = {
      input = [ "text" ];
      output = [ "text" ];
    };
    limit = {
      context = 262144;
      output = 250000;
    };
  };
}
