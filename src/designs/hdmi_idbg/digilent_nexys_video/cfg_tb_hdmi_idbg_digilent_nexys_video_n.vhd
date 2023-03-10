-- for simulators without encrypted (secure) IP support

configuration cfg_oserdese2 of serialiser_10to1_selectio is
  for synth
    for U_SER_M: oserdese2
      use entity work.oserdese2(model);
    end for;
    for U_SER_S: oserdese2
      use entity work.oserdese2(model);
    end for;
  end for;
end configuration cfg_oserdese2;

configuration cfg_hdmi_idbg of hdmi_idbg is
  for synth
    for HDMI_TX_CLK: serialiser_10to1_selectio
      use configuration work.cfg_oserdese2;
    end for;
    for GEN_HDMI_TX_DATA
        for HDMI_TX_DATA: serialiser_10to1_selectio
          use configuration work.cfg_oserdese2;
        end for;
    end for;
  end for;
end configuration cfg_hdmi_idbg;

configuration cfg_hdmi_idbg_digilent_nexys_video of hdmi_idbg_digilent_nexys_video is
  for synth
    for MAIN: hdmi_idbg
      use configuration work.cfg_hdmi_idbg;
    end for;
  end for;
end configuration cfg_hdmi_idbg_digilent_nexys_video;

configuration cfg_tb_hdmi_idbg_digilent_nexys_video of tb_hdmi_idbg_digilent_nexys_video is
  for sim
    for DUT: hdmi_idbg_digilent_nexys_video
      use configuration work.cfg_hdmi_idbg_digilent_nexys_video;
    end for;
  end for;
end configuration cfg_tb_hdmi_idbg_digilent_nexys_video;