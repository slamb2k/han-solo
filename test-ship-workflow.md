# Test Ship Workflow

This file is created to test the complete /hansolo:ship workflow.

## Testing Steps
1. Create this test file
2. Run /hansolo:ship command
3. Monitor PR creation
4. Verify auto-merge and monitoring
5. Confirm auto-sync cleanup

## Expected Behavior
- Ship should detect we're on main
- Should call /hansolo:launch to create branch
- Should create PR via Red Squadron
- Should monitor until merged
- Should call /hansolo:sync for cleanup
- Should end on clean main branch

Test timestamp: 2025-09-19 13:15:00