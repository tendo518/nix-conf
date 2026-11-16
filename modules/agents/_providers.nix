# Local connections. Model capabilities live separately in _models/.
{
  deepseek = {
    name = "DeepSeek";
    secret = "deepseek-api-key";
    defaultModel = "ds_v4flash";
    endpoints = {
      anthropic = "https://api.deepseek.com/anthropic";
      balance = "https://api.deepseek.com/user/balance";
      openai = "https://api.deepseek.com";
    };
    models = {
      ds_v4flash = {
        id = "deepseek-flash";
        model = "deepseek/deepseek-v4.1-flash-1017";
      };
      ds_v4pro = {
        id = "deepseek-v4-pro";
        model = "deepseek/deepseek-v4-pro";
      };
    };
  };
  gpu = {
    name = "GPU";
    secret = "gpu-api-key";
    defaultModel = "qwen3_8_27b";
    endpoints.openai = "http://172.18.36.44:8000/v1";
    models.qwen3_8_27b = {
      id = "qwen3.8-27b";
      model = "alibaba/qwen3.8-27b";
    };
  };
  openai = {
    name = "OpenAI";
    secret = "openai-api-key";
    defaultModel = "gpt_6_1_sol";
    endpoints.openai = "https://api.openai.com/v1";
    models = {
      gpt_6_1_sol = {
        id = "gpt-6.1-sol";
        model = "openai/gpt-6.1-sol";
      };
      gpt_6_astra = {
        id = "gpt-6-astra";
        model = "openai/gpt-6-astra";
      };
      gpt_6_luna = {
        id = "gpt-6-luna";
        model = "openai/gpt-6-luna";
      };
    };
  };
  qwen = {
    name = "Qwen Token Plan";
    secret = "qwen-tokenplan-api-key";
    defaultModel = "qwen3_8_max";
    endpoints = {
      anthropic = "https://token-plan.maas.qianwenaiapi.com/apps/anthropic";
      openai = "https://token-plan.maas.qianwenaiapi.com/compatible-mode/v1";
    };
    models = {
      qwen4_max = {
        id = "qwen4-max";
        model = "alibaba/qwen4-max";
      };
      qwen3_8_max = {
        id = "qwen3.8-max";
        model = "alibaba/qwen3.8-max";
      };
      qwen3_8_flash = {
        id = "qwen3.8-flash";
        model = "alibaba/qwen3.8-flash";
      };
      glm_5_3 = {
        id = "glm-5.3";
        model = "zhipuai/glm-5.3";
      };
      ds_v4_1flash = {
        id = "deepseek-v4.1-flash";
        model = "deepseek/deepseek-v4.1-flash";
      };
      ds_v4_1flash_1017 = {
        id = "deepseek-v4.1-flash-1017";
        model = "deepseek/deepseek-v4.1-flash-1017";
      };
    };
  };
  senseaudio = {
    name = "SenseAudio Token Plan";
    secret = "senseaudio-tokenplan-api-key";
    defaultModel = "ds_v4_1flash";
    endpoints = {
      anthropic = "https://api.senseaudio.cn";
      openai = "https://api.senseaudio.cn/v1";
    };
    models = {
      ds_v4_1flash = {
        id = "deepseek-v4.1-flash";
        model = "deepseek/deepseek-v4.1-flash";
      };
      glm_5_3_flash = {
        id = "glm-5.3-flash";
        model = "zhipuai/glm-5.3-flash";
      };
    };
  };
  stepfun = {
    name = "StepFun Step Plan";
    secret = "stepfun-plan-api-key";
    defaultModel = "step_5_preview";
    endpoints = {
      anthropic = "https://api.stepfun.com/step_plan";
      openai = "https://api.stepfun.com/step_plan/v1";
    };
    models = {
      step_5_preview = {
        id = "step-5-preview";
        model = "stepfun/step-5-preview";
      };
      step_3_7_flash = {
        id = "step-3.7-flash";
        model = "stepfun/step-3.7-flash";
      };
      step_router_v1 = {
        id = "step-router-v1";
        model = "local/step-router-v1";
      };
    };
  };
  volces = {
    name = "Volcengine Coding Plan";
    secret = "volcengine-codingplan-api-key";
    defaultModel = "glm_5_3_flash";
    endpoints = {
      anthropic = "https://ark.cn-beijing.volces.com/api/coding";
      openai = "https://ark.cn-beijing.volces.com/api/coding/v3";
    };
    models = {
      glm_5_3 = {
        id = "glm-5.3";
        model = "zhipuai/glm-5.3";
      };
      glm_5_3_flash = {
        id = "glm-5.3-flash";
        model = "zhipuai/glm-5.3-flash";
      };
    };
  };
}
