import copy
import os
from pathlib import Path
import runpy
import unittest

UPDATER = os.environ.get("AGENT_MODELS_UPDATER") or (
    Path(__file__).resolve().parents[3] / "scripts/update-agent-models.py"
)
select_models = runpy.run_path(str(UPDATER))["select_models"]


class UpdateModelsTests(unittest.TestCase):
    def setUp(self):
        self.facts = {
            "name": "Example",
            "reasoning": True,
            "tool_call": True,
            "modalities": {"input": ["text", "image", "pdf"], "output": ["text"]},
            "limit": {"context": 1050000, "input": 922000, "output": 128000},
        }
        self.providers = {
            "custom": {"models": {"alias": {"id": "api-id", "model": "lab/model"}}}
        }

    def test_only_model_facts_are_imported(self):
        source = {"lab/model": self.facts | {
            "id": "lab/model", "api": "https://example.invalid", "cost": {"input": 1},
            "reasoning_options": [{"type": "effort", "values": ["high"]}],
        }}
        self.assertEqual(select_models(source, self.providers), {"lab/model": self.facts})

    def test_preserves_model_limits_and_modalities(self):
        source = {"lab/model": copy.deepcopy(self.facts)}
        self.assertEqual(select_models(source, self.providers)["lab/model"], self.facts)
        self.assertEqual(source["lab/model"], self.facts)

    def test_shared_models_are_stored_once(self):
        providers = self.providers | {"other": self.providers["custom"]}
        self.assertEqual(list(select_models({"lab/model": self.facts}, providers)), ["lab/model"])

    def test_local_models_are_not_fetched(self):
        providers = {"custom": {"models": {"alias": {"id": "api-id", "model": "local/model"}}}}
        self.assertEqual(select_models({}, providers), {})

    def test_missing_model_does_not_fall_back_to_similar_name(self):
        with self.assertRaisesRegex(ValueError, "lab/model"):
            select_models({"other/model": self.facts}, self.providers)

    def test_result_is_sorted(self):
        providers = {"custom": {"models": {
            "z": {"id": "z", "model": "lab/z"},
            "a": {"id": "a", "model": "lab/a"},
        }}}
        self.assertEqual(list(select_models({"lab/z": self.facts, "lab/a": self.facts}, providers)), ["lab/a", "lab/z"])


if __name__ == "__main__":
    unittest.main()
