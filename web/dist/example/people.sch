<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://www.ascc.net/xml/schematron" 
		    version="1.5" 
			schemaVersion="1.0b1" 
		    xml:lang="en"
		    icon="http://ditchnet.org/texmlmate/images/icon.jpg"
>
	<sch:title>People Schematron</sch:title>

	<sch:p id="main-desc" icon="http://ditchnet.org/texmlmate/images/icon.jpg">What this is about???</sch:p>

	<sch:phase id="phaseOne" icon="http://ditchnet.org/texmlmate/images/icon.jpg">
		<sch:active pattern="patternOne"/>
	</sch:phase>

	<sch:pattern id="patternOne" name="Pattern One">
		<sch:rule context="people">
			<sch:assert test="count(person) = 3" role="tod" subject="@*" diagnostics="my-d">There should be 3 people</sch:assert>
			<sch:assert test="count(person) = 4" subject="." diagnostics="d-1">There should be 4 people</sch:assert>
			<sch:assert test="count(person) = 5" diagnostics="d-2">There should be 5 people</sch:assert>
			<sch:assert test="count(person) = 6">There should be 6 people</sch:assert>
		</sch:rule>
		<sch:rule context="person">
			<sch:report test="firstName" role="skip" subject="." diagnostics="d-1">report 1</sch:report>
			<sch:report test="firstName" subject="." diagnostics="my-d">report 2</sch:report>
			<sch:report test="firstName" diagnostics="d-2">report 3</sch:report>
			<sch:report test="firstName">report 4</sch:report>
		</sch:rule>
	</sch:pattern>
	
	<sch:diagnostics>
		<sch:diagnostic id="d-1">diag 1</sch:diagnostic>
		<sch:diagnostic id="d-2">diag 2</sch:diagnostic>
	</sch:diagnostics>

</sch:schema>