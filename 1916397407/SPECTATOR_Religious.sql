--==========================================================================================================================
-- Observer Support Input by D. / Jack The Narrator
--==========================================================================================================================

UPDATE RequirementSets SET RequirementSetType='REQUIREMENTSET_TEST_ANY' WHERE RequirementSetId='RELIGIOUS_VICTORY_RELIGIOUS_MAJORITY_REQUIREMENTS';
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES ('RELIGIOUS_VICTORY_RELIGIOUS_MAJORITY_REQUIREMENTS', 'REQUIREMENT_OBSERVER_PLAYER_IS_SPECTATOR');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES ('REQUIREMENT_OBSERVER_PLAYER_IS_SPECTATOR', 'REQUIREMENT_PLAYER_LEADER_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES ('REQUIREMENT_OBSERVER_PLAYER_IS_SPECTATOR', 'LeaderType', 'LEADER_SPECTATOR');

