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

configuration cfg_tmds_cap of tmds_cap is
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
end configuration cfg_tmds_cap;

configuration cfg_tmds_cap_digilent_nexys_video of tmds_cap_digilent_nexys_video is
  for synth
    for MAIN: tmds_cap
      use configuration work.cfg_tmds_cap;
    end for;
  end for;
end configuration cfg_tmds_cap_digilent_nexys_video;

configuration cfg_tb_tmds_cap_digilent_nexys_video of tb_tmds_cap_digilent_nexys_video is
  for sim
    for DUT: tmds_cap_digilent_nexys_video
      use configuration work.cfg_tmds_cap_digilent_nexys_video;
    end for;
  end for;
end configuration cfg_tb_tmds_cap_digilent_nexys_video;
