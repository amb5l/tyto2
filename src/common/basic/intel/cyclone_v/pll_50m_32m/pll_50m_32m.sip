set_global_assignment -entity "pll_50m_32m" -library "work" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_50m_32m" -library "work" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_50m_32m" -library "work" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "work" -name SPD_FILE [file join $::quartus(sip_path) "pll_50m_32m.spd"]

set_global_assignment -library "work" -name MISC_FILE [file join $::quartus(sip_path) "pll_50m_32m_sim/pll_50m_32m.vho"]
