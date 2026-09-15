@echo off
setlocal

set "HOI4_MCP_SERVER=%~dp0hoi4_mcp.py"

if not exist "%HOI4_MCP_SERVER%" (
  echo HOI4 local MCP could not find its server file: "%HOI4_MCP_SERVER%" 1>&2
  exit /b 66
)

where py >nul 2>&1
if not errorlevel 1 (
  py -3 "%HOI4_MCP_SERVER%"
  exit /b %errorlevel%
)

where python >nul 2>&1
if not errorlevel 1 (
  python "%HOI4_MCP_SERVER%"
  exit /b %errorlevel%
)

echo HOI4 local MCP requires Python 3, but neither py nor python was found on PATH. 1>&2
exit /b 127
