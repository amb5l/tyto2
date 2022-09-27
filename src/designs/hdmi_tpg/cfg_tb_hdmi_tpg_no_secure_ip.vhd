-- substitute simple simulation model of oserdese2 for encrypted Xilinx model

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

configuration cfg_tb_hdmi_tpg of tb_hdmi_tpg is
  for sim
    for DUT: hdmi_tpg
      for synth
        for HDMI_CLK: serialiser_10to1_selectio
          use configuration work.cfg_oserdese2;
        end for;
        for GEN_HDMI_DATA
            for HDMI_DATA: serialiser_10to1_selectio
              use configuration work.cfg_oserdese2;
            end for;       
        end for;
      end for;
    end for;
  end for;
end configuration cfg_tb_hdmi_tpg;
