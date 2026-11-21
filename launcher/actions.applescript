-- Command Bar Actions: runs launcher actions from cbaction:// links, so they fire on Return only.
-- cbaction://ws/<vault|build|comms|focus|meeting|shutdown>  window layouts (layout.js)
-- cbaction://om                                             Omarchy menu picker
property L : "~/dotfiles/launcher/"

on open location theURL
	set p to text 12 thru -1 of theURL
	if p starts with "ws/" then
		do shell script "/usr/bin/osascript -l JavaScript " & L & "layout.js " & quoted form of (text 4 thru -1 of p) & " >/dev/null 2>&1 &"
	else if p is "om" then
		pickOmarchy()
	end if
end open location

on run
	pickOmarchy()
end run

on pickOmarchy()
	set rows to paragraphs of (do shell script "/usr/bin/python3 " & L & "om_pick.py")
	set titles to {}
	set argsList to {}
	set AppleScript's text item delimiters to tab
	repeat with r in rows
		if (count of text items of r) is 2 then
			set end of titles to text item 1 of r
			set end of argsList to text item 2 of r
		end if
	end repeat
	set AppleScript's text item delimiters to ""
	activate
	set picked to choose from list titles with title "Omarchy menu" with prompt "Pick an action" OK button name "Run"
	if picked is false then return
	repeat with i from 1 to count of titles
		if item i of titles is (item 1 of picked) then
			do shell script "/bin/bash " & L & "om_run.sh " & quoted form of (item i of argsList) & " >/dev/null 2>&1 &"
			exit repeat
		end if
	end repeat
end pickOmarchy
