configuration TbR6522_BasicRegReadWrite of TbR6522 is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(BasicRegReadWrite) ; 
    end for ; 
  end for ; 
end configuration TbR6522_BasicRegReadWrite ; 
