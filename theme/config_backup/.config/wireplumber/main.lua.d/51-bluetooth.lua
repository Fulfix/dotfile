rule = {
  matches = {
    {
      { "node.name", "matches", "bluez_output.*" },
    },
  },
  apply_properties = {
    ["audio.format"] = "S16LE",
    ["audio.rate"] = 48000,
    ["api.alsa.period-size"] = 1024,
    ["api.alsa.headroom"] = 0,
  },
}

table.insert(alsa_monitor.rules,rule)
