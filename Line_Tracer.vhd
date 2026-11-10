   library ieee;
   use ieee.std_logic_1164.all;

   entity Line_Tracer is
      port(
            in_bit : in bit_vector (0 to 7);
            clk, sw0, sw9, sw1: in std_logic; 
            LED : out bit_vector   (0 to 7);
            seg0, seg1, seg2, seg3 : out std_logic_vector(7 downto 0);
            Motor_L, Motor_R   :   out std_logic);
            
   end Line_Tracer;

   architecture arc of Line_Tracer is
      signal carry_cnt : integer range 0 to 50000 :=0;
      signal input1 : integer range 0 to 100;
      signal input2 : integer range 0 to 100;
      signal LINE_FLAG   :   std_logic   :=   '0';
      signal e_flag : std_logic := '0';
      
      type weight_array_t is array (0 to 7) of integer;
      constant WEIGHT:   weight_array_t   :=   (12000,6000,3000,1500,-1500,-3000,-6000,-12000);

      constant speed_standard   :   integer   :=   15000;
      
      type state_type is   (Mr,M0,M1,M2,M3,M4,M5,M6,M7,M8,M9,M10,M11);
      signal state   :   state_type   :=   Mr;
      
   begin
      
      process(clk, in_bit, sw0, sw9, sw1)
         variable count : integer range 0 to 50000000 := 0;
         variable e_count : integer range 0 to 150000000 := 0;
         variable count_fsm   :   integer range 0 to 500000   :=   0;
         
         variable fsm_carry   :   integer range 0 to 20;
         variable fsm_on   :   std_logic   :=   '0';
         variable NUM_BLACK   :   integer range 0 to 8   :=   0;
         variable LINECHECK   :   integer range 0 to 1   :=   1;
         
         variable weightedspeed   :   integer   :=   0;
         variable Lspeed   :   integer   :=   0;
         variable Rspeed   :   integer   :=   0;
         variable speed_add   :   integer   :=   0;

      begin
         if rising_edge(clk) then
            NUM_BLACK   :=   0;
            
            LED <= not in_bit;
         
            for i in 0 to 7 loop
               if(in_bit(i) = '0') then
                  NUM_BLACK := NUM_BLACK + 1;
               end if;         
            end loop;
         
            count := count + 1;
            count_fsm   :=   count_fsm   +   1;
            
            if (count = 499999) then
               count := 0;
               input1 <= input1 + 1;   --0.01sec
               
               if (input1 = 99) then
                  input1 <= 0;
                  input2 <= input2 + 1;   --1sec
               end if;
               
                  
            end if;
            
            if (count_fsm   =   499999) then
               count_fsm   :=   0;
               fsm_carry   :=   fsm_carry   +   1;
               
               if (fsm_carry = 1)   then      --0.01sec
                  fsm_carry   :=   0;
                  fsm_on   :=   '1';
               end if;
               
            end if;
            
            carry_cnt <= carry_cnt + 1;
            
            if(carry_cnt >= 49999) then
               carry_cnt <= 0;
            end if;
            
            if (fsm_on   =   '1') then
               if (NUM_BLACK < 4) then
                  LINE_FLAG   <=   '0';
               end if;
               
               case state is
                  when Mr   =>                              --ready
                     if   (sw0   =   '1') then
                        state   <=   M0;
                     else
                        state   <=   Mr;
                     end if;
               
                  when M0   =>                              --black line 1 (jump)
                     if (NUM_BLACK   >=   6) then
                        state   <=   M1;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M0;
                     end if;
         
                  when M1   =>                              --black line 2 (drive)
                     if (NUM_BLACK   >=   6 and LINE_FLAG   =   '0') then
                        state   <=   M2;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M1;
                     end if;
            
                  when M2   =>                              --black line 3(wait 3 sec)
                     if (NUM_BLACK   >=   5 and LINE_FLAG   =   '0') then
                        state   <=   M3;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M2;
                     end if;
                     
                  when M3   =>                              --black line 4(speed up)
                     if (NUM_BLACK   >=   5 and LINE_FLAG   =   '0') then
                        state   <=   M4; 
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M3;
                     end if;
               
                  when M4   =>                              --black line 5(speed reset)
                     if (NUM_BLACK   >=   7 and LINE_FLAG   =   '0') then
                        state   <=   M5;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M4;
                     end if;
                  
                  when M5   =>                              --square(turn)
                     if (NUM_BLACK   >=   4 and LINE_FLAG   =   '0') then
                        state   <=   M6;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M5;
                     end if;
                        
                  when M6   =>                              --square(turn)
                     if (NUM_BLACK   >=   4 and LINE_FLAG   =   '0' and e_flag   =   '1') then
                        state   <=   M7;
                        LINE_FLAG   <=   '1';
                        e_flag   <=   '0';
                     else
                        state   <=   M6;
                     end if;
               
                  when M7   =>                              --T(select way by switch)
                     if (e_flag   =   '1') then
                        e_flag   <=   '0';
                        state   <=   M8;
                        LINE_FLAG   <=   '1';
                     else
                        state   <=   M7;
                     end if;   
               
                  when M8   =>                              --square(turn)
                     if (NUM_BLACK   >=   5 and LINE_FLAG   =   '0') then
                        state   <=   M9;
                        LINE_FLAG   <=   '1';
                        e_flag   <=   '0';
                     else
                        state   <=   M8;
                     end if;
               
                  when M9   =>                              --black line 6(break after 1.5 sec)
                     if (NUM_BLACK   >=   7 and LINE_FLAG = '0') then
                        state   <=   M10;
                     else
                        state   <=   M9;
                     end if;
                  
                  when M10   =>                              --race finish
                     if (sw0   =   '0') then
                        state   <=   M11;
                     else
                        state   <=   M10;
                     end if;
                     
                  when M11   =>
                     if   (sw1   =   '1') then
                        state   <=   Mr;
                     else
                        state   <=   M11;
                     end if;
               
               end case;
               
               if (state   =   M6) then
                  if(in_bit(1) = '0' and in_bit(2) = '0' and e_flag = '0')   then
                     e_flag   <=   '1';
                  end if;
               end if;
               
               if (state   =   M7) then
                 if(in_bit(1) = '0' and in_bit(0) = '0' and e_flag = '0')   then
                    e_flag   <=   '1';
                 end if;
               end if;
               
               if (state = M8) then
                  if (sw9 = '0' and e_flag = '0') then
                     if(in_bit(1) = '1' and in_bit(0) = '1' and LINECHECK = 1) then
                        LINECHECK   :=   0;
                     elsif(in_bit(1) = '0' and in_bit(0) = '0' and LINECHECK = 0)   then
                        e_flag  <=  '1';
                        LINECHECK   :=   1;
                     end if;
                  elsif   (sw9   =   '0' and e_flag   =   '1' and LINECHECK   =   1) then
                     if(in_bit(6)   =   '0' and in_bit(7)   =   '0') then
                        LINECHECK   :=   0;
                     end if;
                  
                  elsif (sw9 = '1' and e_flag = '0') then
                     if(in_bit(3) = '0' and in_bit(4) = '0') then
                        e_flag <= '1';
                     end if;
                  end if;
               end if;
               
               if (state = M9) then
                  if (sw9 = '0' and e_flag = '0') then
                     if(in_bit(6) = '0')   then
                        e_flag  <=  '1';
                     end if;
                  
                  elsif (sw9 = '1' and e_flag = '0') then
                     if(in_bit(1) = '0') then
                        e_flag <= '1';
                     end if;
                  end if;
               end if;
            
               fsm_on   :=   '0';
               
            end if;
            
            for i in 0 to 7 loop
               if in_bit(i) = '0' then
                  weightedspeed   :=   weightedspeed   +   WEIGHT(i);
               end if;
            end loop;
                  
            Lspeed   :=   (speed_standard + speed_add) + weightedspeed;
            Rspeed   :=   (speed_standard + speed_add) - weightedspeed;   
            
            if (state   =   Mr) then
               Lspeed   :=   0;
               Rspeed   :=   0;
               count   :=    0;
               input1   <=   0;
               input2   <=   0;
               e_flag   <=   '0';
               LINECHECK   :=   1;
               
            elsif (state   =   M1) then
               LED   <=   "11111111";
            
               Lspeed   :=   35000;
               Rspeed   :=   35000;
               
            elsif (state   =   M3) then
               e_count := e_count + 1;
               if (e_count < 149999999 and e_flag = '0') then
                  Lspeed := 0;
                  Rspeed := 0;
               elsif (e_count = 149999999) then
                  e_flag <= '1';
               end if;
               
            elsif (state   =   M4) then
               if (e_flag = '1') then
                  e_count := 0;
                  e_flag <= '0';
               end if;
               speed_add := 10000;
               
            elsif   (state = M5) then
               speed_add := 0;
               
            elsif (state = M6 or state = M7) then
               if (e_flag = '0') then
                  Lspeed := 0;
                  Rspeed := 40000;
               end if;
               
            elsif   (state = M8) then
               speed_add   :=   -4000;
               
               if (sw9 = '0') then
                  if (e_flag = '0') then
                     Lspeed := 0;
                     Rspeed := 30000;
                  elsif   (e_flag   =   '1' and LINECHECK   =   1) then
                     Lspeed   :=   30000;
                     Rspeed   :=   0;
                  end if;
                  
               elsif (sw9 = '1') then
                  if (e_flag = '0') then
                     Lspeed := 40000;
                     Rspeed := 0;
                  end if;
               end if;
               
            elsif   (state   =   M9) then
               speed_add   :=   0;
               
               if (sw9 = '0') then
                  if (e_flag = '0') then
                     Lspeed := 0;
                     Rspeed := 40000;
                  end if;
                  
               elsif (sw9 = '1') then
                  if (e_flag = '0') then
                     Lspeed := 40000;
                     Rspeed := 0;
                  end if;
               end if;
               
            elsif   (state =  M10 or state   =   M11) then
               Lspeed := 0;
               Rspeed := 0;
               count   :=   0;
            end if;
            
            if (carry_cnt >= Lspeed) then
               Motor_L <= '0';
            elsif (carry_cnt < Lspeed) then
               Motor_L <= '1';
            end if;
      
            if (carry_cnt >= Rspeed) then
               Motor_R <= '0';
            elsif (carry_cnt < Rspeed) then
               Motor_R <= '1';
            end if;
         
            weightedspeed := 0;
            
         end if;
         
      end process;
      
      process(input1,input2,state)
      
      begin
         
         if (state  =  Mr) then
            seg0 <= "00001100";
            seg1 <= "11000000";
            seg2 <= "10000111";
            seg3 <= "10010010";
            
         elsif (state  =  M11) then
            seg0 <= "01001000";
            seg1 <= "11111001";
            seg2 <= "10001110";
            seg3 <= "11111111";
            
         else
            case (input1 mod 10) is
               when 0 =>       seg0 <="11000000";
               when 1 =>       seg0 <="11111001";
               when 2 =>       seg0 <="10100100";
               when 3 =>       seg0 <="10110000";
               when 4 =>       seg0 <="10011001";
               when 5 =>       seg0 <="10010010";
               when 6 =>       seg0 <="10000010";
               when 7 =>       seg0 <="11011000";
               when 8 =>       seg0 <="10000000";
               when 9 =>       seg0 <="10011000";
               when others =>  seg0 <="11111111";
            end case;
         
            case (input1 / 10) is
               when 0 =>       seg1 <="11000000";
               when 1 =>       seg1 <="11111001";
               when 2 =>       seg1 <="10100100";
               when 3 =>       seg1 <="10110000";
               when 4 =>       seg1 <="10011001";
               when 5 =>       seg1 <="10010010";
               when 6 =>       seg1 <="10000010";
               when 7 =>       seg1 <="11011000";
               when 8 =>       seg1 <="10000000";
               when 9 =>       seg1 <="10011000";
               when others =>  seg1 <="11111111";
            end case;
         
            case (input2 mod 10) is
               when 0 =>       seg2 <="01000000";
               when 1 =>       seg2 <="01111001";
               when 2 =>       seg2 <="00100100";
               when 3 =>       seg2 <="00110000";
               when 4 =>       seg2 <="00011001";
               when 5 =>       seg2 <="00010010";
               when 6 =>       seg2 <="00000010";
               when 7 =>       seg2 <="01011000";
               when 8 =>       seg2 <="00000000";
               when 9 =>       seg2 <="00011000";
               when others =>  seg2 <="01111111";
            end case;
         
            case (input2 / 10) is
               when 0 =>       seg3 <="11000000";
               when 1 =>       seg3 <="11111001";
               when 2 =>       seg3 <="10100100";
               when 3 =>       seg3 <="10110000";
               when 4 =>       seg3 <="10011001";
               when 5 =>       seg3 <="10010010";
               when 6 =>       seg3 <="10000010";
               when 7 =>       seg3 <="11011000";
               when 8 =>       seg3 <="10000000";
               when 9 =>       seg3 <="10011000";
               when others =>  seg3 <="11111111";
            end case;
            
         end if;
      end process;
   end arc;      