-- autostart.lua

hl.on("hyprland.start", function()
  -- --daemon returns once the shell is initialised (the polkit agent starts
  -- asynchronously just after the UI is up).
  hl.exec_cmd("noctalia --daemon")
end)
