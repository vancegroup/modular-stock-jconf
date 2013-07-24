#!/usr/bin/env lua

aspect_ratios = {
	{
		ratio = {16, 9};
		resolution = {1920, 1080};
		sizes = {15, 23}
	};
	{
		ratio = {16, 10};
		resolution = {1920, 1200};
		sizes = {13.3, 20, 24};
	};
	{
		ratio = {5, 4};
		resolution = {1280, 1024};
		sizes = {17};
	};
	{
		ratio = {4, 3};
		resolution = {1600, 1200};
		sizes = {20};
	};
}

widthHeight = function(diagonal, ratio)
	local W = ratio[1]
	local H = ratio[2]
	local height = diagonal * math.sqrt((H*H)/(W*W + H*H))
	local width = (W/H) * height
	return width, height
end

-- Average of average male and female adult height in US ~1.7 m, so we want the display to roughly simulate that.
-- Monitors are on the order of 20 cm tall, so the bottom could reasonably be at 1.69m
bottomHeight = 1.69

inchToMeter = function(inch) return inch * .0254 end

getStart = function(x, y)
	return ([[
<?xml version="1.0" encoding="UTF-8"?>
<?org-vrjuggler-jccl-settings configuration.version="3.0"?>
<configuration xmlns="http://www.vrjuggler.org/jccl/xsd/3.0/configuration" name="Configuration" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vrjuggler.org/jccl/xsd/3.0/configuration http://www.vrjuggler.org/jccl/xsd/3.0/configuration.xsd">
   <elements>
   <display_window name="FishtankVR" version="6">
         <origin>0</origin>
         <origin>0</origin>
         <size>%d</size>
         <size>%d</size>
         <pipe>0</pipe>
         <frame_buffer_config>
            <opengl_frame_buffer_config name="GL Frame Buffer" version="4">
               <visual_id>-1</visual_id>
               <red_size>1</red_size>
               <green_size>1</green_size>
               <blue_size>1</blue_size>
               <alpha_size>1</alpha_size>
               <auxiliary_buffer_count>0</auxiliary_buffer_count>
               <depth_buffer_size>1</depth_buffer_size>
               <stencil_buffer_size>1</stencil_buffer_size>
               <accum_red_size>1</accum_red_size>
               <accum_green_size>1</accum_green_size>
               <accum_blue_size>1</accum_blue_size>
               <accum_alpha_size>1</accum_alpha_size>
               <num_sample_buffers>0</num_sample_buffers>
               <num_samples>0</num_samples>
               <use_create_context_attribs>false</use_create_context_attribs>
               <gl_context_major_version>3</gl_context_major_version>
               <gl_context_minor_version>0</gl_context_minor_version>
               <gl_context_flags>0</gl_context_flags>
            </opengl_frame_buffer_config>
         </frame_buffer_config>
         <stereo>false</stereo>
         <border>false</border>
         <hide_mouse>true</hide_mouse>
         <full_screen>true</full_screen>
         <always_on_top>false</always_on_top>
         <active>true</active>
         <surface_viewports>
            <surface_viewport name="VRViewport" version="3">
               <origin>0.0</origin>
               <origin>0.0</origin>
               <size>1.0</size>
               <size>1.0</size>
               <view>Left Eye</view>
]]):format(x, y)
end

getCorners = function(w, h)
	local cornerSubstitutions = {
		bottom = bottomHeight,
		top = bottomHeight + h,
		halfwidth = w/2
	}
	return ([[
               <lower_left_corner>-$halfwidth</lower_left_corner>
               <lower_left_corner>$bottom</lower_left_corner>
               <lower_left_corner>0.0</lower_left_corner>
               <lower_right_corner>$halfwidth</lower_right_corner>
               <lower_right_corner>$bottom</lower_right_corner>
               <lower_right_corner>0.0</lower_right_corner>
               <upper_right_corner>$halfwidth</upper_right_corner>
               <upper_right_corner>$top</upper_right_corner>
               <upper_right_corner>0.0</upper_right_corner>
               <upper_left_corner>-$halfwidth</upper_left_corner>
               <upper_left_corner>$top</upper_left_corner>
               <upper_left_corner>0.0</upper_left_corner>]]):gsub("$(%w+)", function(name) return cornerSubstitutions[name] end)
end

templateEnd = [[
               <user>User1</user>
               <active>true</active>
               <tracked>false</tracked>
               <tracker_proxy />
               <auto_corner_update>0</auto_corner_update>
            </surface_viewport>
         </surface_viewports>
         <keyboard_mouse_device_name>Keyboard/Mouse Device</keyboard_mouse_device_name>
         <allow_mouse_locking>false</allow_mouse_locking>
         <lock_key>KEY_NONE</lock_key>
         <start_locked>false</start_locked>
         <sleep_time>75</sleep_time>
      </display_window>
   </elements>
</configuration>
]]

for _, aspect in ipairs(aspect_ratios) do
	print()
	print("Ratio", aspect.ratio[1], aspect.ratio[2])
	print("Sample Resolution", aspect.resolution[1], aspect.resolution[2])
	for _, diagonalInches in ipairs(aspect.sizes) do
		local fn = ("display.fishtank-%d-%d-aspect-%d-inch.jconf"):format(aspect.ratio[1], aspect.ratio[2], diagonalInches)
		print("Writing", fn)
		local w, h = widthHeight(inchToMeter(diagonalInches), aspect.ratio)
		print(tostring(diagonalInches) .. '"', w, h)
		
		local f = assert(io.open(fn, "w"))
		f:write(getStart(aspect.resolution[1], aspect.resolution[2]))
		f:write(getCorners(w, h))
		f:write(templateEnd)
		f:close()
	end

end
