"""GoalSight Analysis Service — FastAPI layer that wraps the football_ai model.

This package does NOT modify the model. It imports the model's own
``main.py`` module-level orchestration functions (``run_minimap``,
``run_possession``, ``run_role_refinement`` ...) plus ``RoleCorrectionRunner``
and drives them in two stages (detect → name → full analysis), exactly the
way ``main.py`` does, but with player names supplied from the mobile app via a
corrections JSON instead of the desktop Tkinter review UI.
"""
