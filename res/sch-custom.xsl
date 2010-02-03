<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:t="http://scan.dalo.us/xmlmate"
	xmlns:sch="http://www.ascc.net/xml/schematron">

<xsl:import href="skeleton-1.5.xsl"/>

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:param name="verbose" select="true()"/>
<xsl:param name="sourceURLString"/>
<xsl:param name="schemaURLString"/>

<xsl:template name="process-root">
	<xsl:param name="contents"/>
	<xsl:param name="title"/>
	<xsl:param name="icon"/>
	<xsl:param name="version"/>
	<xsl:param name="schemaVersion"/>
	<xsl:param name="lang"/>
	<!-- unused params: fpi, id -->
	
	<html>
		<xsl:if test="$lang">
			<xsl:attribute name="xml:lang"><xsl:value-of select="$lang"/></xsl:attribute>
		</xsl:if>
		<head>
			<title><xsl:value-of select="$title"/></title>
			<style type="text/css">

				body {
					display:block;
					width:100%;
					margin:0;
					padding:0;
				}

				#result-list {
					display:block;
					min-width:100%;
					margin:0;
					padding:0;
				}

				li {
					margin:0;
					padding:6px 5px 3px 35px;
					border-bottom:1px solid #ccc;
					font:10px LucidaGrande,sans-serif;
					word-wrap:break-word;
					min-height:15px;
				}

				li:hover {
					background-color:#f6f6f6 !important
				}

				li strong {
					font-weight:bold;
					text-transform:uppercase;
				}

				li pre {
					display:inline;
					text-decoration:none;
					font:9px Monaco;
					color:rgb(166, 84, 0);
					//word-wrap:normal;
					clear:both;
				}

				tt {
					font:9px Monaco;
				}

				.info-item {
					background:white url(images/info-icon-small.png) 10px 50% no-repeat;
				}


				.error-item {
					cursor:pointer;
					background:#fbe7e7 url(images/error-icon-small.png) 10px 50% no-repeat;
				}

				.warning-item {
					cursor:pointer;
					background:#FAFDCA url(images/warning-icon-small.png) 10px 50% no-repeat;
				}

				.success-item {
					background:#e2fdda url(images/success-icon-small.png) 10px 50% no-repeat;
				}

				.report-item {
					cursor:pointer;
					background:rgb(242, 245, 255) url(images/info-icon-small.png) 10px 50% no-repeat;
				}
				.assert-item {
					cursor:pointer;
					background:#fbe7e7 url(images/error-icon-small.png) 10px 50% no-repeat;
				}
			</style>
		</head>
		<body>
			<ul id="result-list">
				<li class="info-item">
					Evaluating <tt><xsl:value-of select="$sourceURLString"/></tt>
					against Schematron schema <tt><xsl:value-of select="$schemaURLString"/></tt>
				</li>
				<xsl:if test="$title">
					<li class="info-item">
						<xsl:if test="$icon">
							<img src="{$icon}" width="16" height="16" style="float:left; clear:both" alt="icon"/>
						</xsl:if>
						<xsl:value-of select="$title"/>
					</li>
				</xsl:if>

				<xsl:if test="$version or $schemaVersion">
					<li class="info-item">
						<xsl:if test="$version">
							Schematron version: <tt><xsl:value-of select="$version"/></tt>
							<br/>
						</xsl:if>
						<xsl:if test="$schemaVersion">
							Schema version: <tt><xsl:value-of select="$schemaVersion"/></tt>
						</xsl:if>
					</li>
				</xsl:if>
			
				<xsl:copy-of select="$contents"/>
			</ul>
		</body>
	</html>
</xsl:template>


<xsl:template name="process-assert">
	<xsl:param name="role"/>
	<xsl:param name="test"/>
	<xsl:param name="subject"/>
	<xsl:param name="diagnostics"/>
	<!-- unused parameters: id, icon -->
	
	<t:assert-fired role="{$role}" test="{$test}">
		<t:msg>
			<xsl:call-template name="process-message">
				<xsl:with-param name="pattern" select="$test"/>
				<xsl:with-param name="role" select="$role"/>
			</xsl:call-template>
		</t:msg>
		<t:diag><xsl:value-of select="//sch:diagnostic[@id = $diagnostics]"/></t:diag>
		<t:subj><xsl:value-of select="$subject"/></t:subj>
	</t:assert-fired>

</xsl:template>


<xsl:template name="process-report">
	<xsl:param name="role"/>
	<xsl:param name="test"/>
	<xsl:param name="subject"/>
	<xsl:param name="diagnostics"/>
	<!-- unused parameters: id, icon -->

	<t:report-fired test="{$test}" role="{$role}">
		<t:msg>
			<xsl:call-template name="process-message">
				<xsl:with-param name="pattern" select="$test"/>
				<xsl:with-param name="role" select="$role"/>
			</xsl:call-template>
		</t:msg>
		<t:diag><xsl:value-of select="//sch:diagnostic[@id = $diagnostics]"/></t:diag>
		<t:subj><xsl:value-of select="$subject"/></t:subj>
	</t:report-fired>

</xsl:template>


<xsl:template name="process-message">
	<xsl:param name="pattern"/>
	<xsl:param name="role"/>
	<!-- params: pattern, role -->
	<xsl:apply-templates mode="text"/>
</xsl:template>


</xsl:stylesheet>