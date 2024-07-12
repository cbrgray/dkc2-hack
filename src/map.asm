include

every_map_frame:
		STZ !dropped_frames
		STZ !real_frames_elapsed
		STZ !timer_frames
		STZ !timer_seconds
		STZ !timer_minutes
		STZ !timer_disp_frames
		STZ !timer_disp_seconds
		STZ !timer_disp_minutes
		STZ !timer_stopped
		STZ !timer_started
		LDA !counter_60hz
		STA !previous_60hz

		JSR check_goto_overworld
		JSR check_kong_swap

		SEP #$20
		LDA $0512
		RTL


check_goto_overworld:
		; using the hardware reg here since the game doesn't clear controller data when start+select-ing out of a stage
		LDA !reg_joy1h : BIT #$0020 : BEQ .done ; select pressed?

		; the nmi_pointer selects the address in bank $80 to run at the start of each frame
		; $8087D9 jumps to $B5CDFD, which loads a world map screen based on the value in map_index
		LDA #$87D9 : STA !nmi_pointer_dp
		STZ !map_index ; 0 = overworld

		; $06AF/B0 seems to store a movement value for when the kongs move between map nodes
		; if you try to load the overworld while this is non-zero, you will softlock as they run offscreen
		STZ $06AF

		; $06AD seems to store a value that dictates where the kongs move after beating a level
		; it gets set even when they don't move automatically, and is only cleared when a new node is reached
		; zeroing it prevents another softlock when loading the overworld immediately after beating a level
		STZ $06AD
	.done:
		RTS

check_kong_swap:
		; if L was pressed, toggle between 1 or 2 kongs
		LDA !io_axlr_1f
		BIT #$0020
		BEQ .check_swap

		; toggle sprite visibility
		LDX !follower_kong
		LDA $1C,x
		EOR #$C000
		STA $1C,x

		; toggle extra kong
		LDA !extra_kong_flag
		EOR #$4000
		STA !extra_kong_flag

	.check_swap:
		; if R was pressed, change which kong is in front
		LDA !io_axlr_1f
		BIT #$0010
		BEQ .done

		; toggle between diddy and dixie
		LDA !current_map_kong
		EOR #$0001
		STA !current_map_kong

		; toggle animation number for both main and follower kongs
		LDX !main_kong
		LDA $36,x
		EOR #$0003
		STA $36,x
		LDX !follower_kong
		LDA $36,x
		EOR #$0003
		STA $36,x
	.done:
		RTS
