# APEX Application Export

APEX 24.2 app ekhane export kore rakhben (Git e track hobe).

**Export:** App Builder → App (101) → Export/Import → Export → Format: *SQL* → `f101.sql` ei folder e save
**Import (onno PC):** App Builder → Import → `f101.sql` → Install

Custom Authentication:
Shared Components → Authentication Schemes → Create → *Custom* → Authentication Function Name: `PKG_AUTH.AUTHENTICATE`
