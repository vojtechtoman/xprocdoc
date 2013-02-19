<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xd="http://www.emc.com/documentum/xml/xproc/doc"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:param name="product"/>
  <xsl:param name="input-base-uri"/>
  <xsl:param name="output-base-uri"/>
  <xsl:param name="overview-file"/>

  <xsl:output name="xhtml-frameset" method="xhtml"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"
              doctype-public="-//W3C//DTD XHTML 1.0 Frameset//EN"/>



  <xsl:template match="xd:summary">
    <xsl:call-template name="create-library-index"/>
    <xsl:call-template name="create-library-details"/>
    <xsl:call-template name="create-step-index"/>
    <xsl:call-template name="create-step-details"/>
    <xsl:call-template name="create-overview"/>
    <xsl:call-template name="create-index"/>
    <foo/>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-index">
    <xsl:variable name="main-title" select="concat($product, ' XProc API documentation')"/>
    <xsl:result-document format="xhtml-frameset" href="{resolve-uri('index.html', $output-base-uri)}">
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title" select="$main-title"/>
        </xsl:call-template>
        <frameset cols="20%,80%">
          <frameset rows="30%,70%">
            <frame src="libraries.html"/>
            <frame src="steps.html"/>
          </frameset>
          <frame src="overview.html" name="detail"/>
          <noframes>
            <body>
              <p>Your browser does not support frames.</p>
            </body>
          </noframes>
        </frameset>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-library-index">
    <xsl:result-document format="xhtml-frameset" href="{resolve-uri('libraries.html', $output-base-uri)}">
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title">Library Index</xsl:with-param>
        </xsl:call-template>
        <body>
          <div><a href="index.html" target="_top">Home</a></div>
          <h3>All Libraries</h3>
          <xsl:choose>
            <xsl:when test="//xd:library">
              <xsl:apply-templates select="//xd:library" mode="library-index">
                <xsl:sort select="xd:relativize(../@href, $input-base-uri)"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <div>(Empty)</div>
            </xsl:otherwise>
          </xsl:choose>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-overview">
    <xsl:variable name="overview-title" select="if ($product != '') then concat ('Overview (', $product, ')') else 'Overview'"/>
    <xsl:result-document format="xhtml-frameset" href="{resolve-uri('overview.html', $output-base-uri)}">
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title" select="$overview-title"/>
        </xsl:call-template>
        <body>
          <h2><xsl:value-of select="$overview-title"/></h2>

          <xsl:if test="$overview-file != ''">
            <xsl:copy-of select="doc($overview-file)"/>
          </xsl:if>

          <xsl:if test="//xd:library">
            <h3>Libraries</h3>
            <table border="1">
              <thead>
                <tr>
                  <td>Location</td>
                  <td>Description</td>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates select="//xd:library" mode="table-row">
                  <xsl:sort select="xd:relativize(../@href, $input-base-uri)"/>
                </xsl:apply-templates>
              </tbody>
            </table>
          </xsl:if>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-library-details">
    <xsl:apply-templates select="//xd:library" mode="detail"/>
  </xsl:template>

  <!-- -->

  <xsl:template match="xd:library" mode="library-index">
    <div class="nowrap name">
      <xsl:call-template name="nodelink">
        <xsl:with-param name="linktext" select="xd:relativize(../@href, $input-base-uri)"/>
      </xsl:call-template>
    </div>
  </xsl:template>

  <!-- -->

  <xsl:template match="xd:library" mode="table-row">
    <tr>
      <td width="150px" class="nowrap name">
        <xsl:call-template name="nodelink">
          <xsl:with-param name="linktext"><xsl:value-of select="xd:relativize(../@href, $input-base-uri)"/></xsl:with-param>
        </xsl:call-template>
      </td>
      <td>
        <xsl:apply-templates select="xd:documentation" mode="doc-excerpt"/>
      </td>
    </tr>
  </xsl:template>

  <!-- -->

  <xsl:template match="xd:library" mode="detail">
    <xsl:variable name="source-href"><xsl:value-of select="xd:relativize(../@href, $input-base-uri)"/></xsl:variable>
    <xsl:variable name="result-href"><xsl:value-of select="resolve-uri(xd:generate-output-uri(.), $output-base-uri)"/></xsl:variable>
    <xsl:result-document format="xhtml-frameset" href="{$result-href}">
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title" select="$source-href"></xsl:with-param>
        </xsl:call-template>

        <body>
          <h2>Library <span class="name"><xsl:value-of select="$source-href"/></span></h2>

          <xsl:apply-templates select="xd:documentation"/>

          <xsl:if test="xd:import">
            <h3>Imports</h3>
            <ul>
              <xsl:for-each select="xd:import">
                <xsl:variable name="import-href" select="@href"/>
                <xsl:variable name="import-target" select="//xd:source[@href=$import-href and (xd:library or xd:step[@type != ''])]"/>
                <xsl:if test="$import-target">
                  <!-- import points to a library or to a step with type information -->
                  <li>
                    <span class="uri">
                      <a href="{xd:generate-output-uri($import-target/*[1])}"><xsl:value-of select="xd:relativize($import-href, $input-base-uri)"/></a>
                    </span>
                 </li>
                </xsl:if>
              </xsl:for-each>
            </ul>
          </xsl:if>

          <xsl:if test="xd:step">
            <h3>Steps</h3>
            <table border="1">
              <thead>
                <tr>
                  <td>Local Name</td>
                  <td>Namespace URI</td>
                  <td>Description</td>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates select="xd:step" mode="table-row">
                  <xsl:sort select="concat(@local-name, @namespace-uri)"/>
                </xsl:apply-templates>
              </tbody>
            </table>
          </xsl:if>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-step-index">
    <xsl:result-document format="xhtml-frameset" href="{resolve-uri('steps.html', $output-base-uri)}">
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title">Step Index</xsl:with-param>
        </xsl:call-template>
        <body>
          <h3>All Steps</h3>
          <xsl:choose>
            <xsl:when test="//xd:step">
              <xsl:apply-templates select="//xd:step" mode="step-index">
                <xsl:sort select="concat(@local-name, @namespace-uri)"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <div>(Empty)</div>
            </xsl:otherwise>
          </xsl:choose>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- -->

  <xsl:template name="create-step-details">
    <xsl:apply-templates select="//xd:step" mode="detail"/>
  </xsl:template>


  <!-- -->

  <xsl:template match="xd:step" mode="step-index">
    <div class="nowrap name">
      <xsl:call-template name="nodelink">
        <xsl:with-param name="linktext">
          <xsl:value-of select="xd:step-local-name(@local-name)"/>&#160;<span class="small uri"><xsl:value-of select="xd:step-namespace-uri(@namespace-uri)"/></span>
        </xsl:with-param>
      </xsl:call-template>
    </div>
  </xsl:template>

  <!-- -->

  <xsl:template match="xd:step" mode="table-row">
    <tr>
      <td width="150px" class="nowrap name">
        <xsl:call-template name="nodelink">
          <xsl:with-param name="linktext"><xsl:value-of select="@local-name"/></xsl:with-param>
        </xsl:call-template>
      </td>
      <td width="150px" class="nowrap uri">
        <xsl:value-of select="@namespace-uri"/>
      </td>
      <td>
        <xsl:apply-templates select="xd:documentation" mode="doc-excerpt"/>
      </td>
    </tr>
  </xsl:template>

  <!-- -->

  <xsl:template match="xd:step" mode="detail">
    <xsl:variable name="source-href" select="xd:relativize(ancestor::xd:source/@href, $input-base-uri)"/>
    <xsl:variable name="step-local-name" select="xd:step-local-name(@local-name)"/>
    <xsl:variable name="step-namespace-uri" select="xd:step-namespace-uri(@namespace-uri)"/>
    <xsl:variable name="result-href"><xsl:value-of select="resolve-uri(xd:generate-output-uri(.), $output-base-uri)"/></xsl:variable>
    <xsl:result-document format="xhtml-frameset" href="{$result-href}">
      
      <html>
        <xsl:call-template name="head">
          <xsl:with-param name="title" select="concat($step-local-name, ' ', $step-namespace-uri)"/>
        </xsl:call-template>
        <body>
          <h2>
            Step <span class="name"><xsl:value-of select="$step-local-name"/></span>
            <xsl:if test="@namespace-uri != ''">&#160;<span class="uri"><xsl:value-of select="$step-namespace-uri"/></span>
            </xsl:if>
          </h2>

          <xsl:apply-templates select="xd:documentation"/>

          <div>Defined in:
          <span class="uri">
            <xsl:choose>
              <xsl:when test="ancestor::xd:library">
                <!-- for steps in a librayr, generate a link to the library -->
                <a href="{xd:generate-output-uri(ancestor::xd:library)}"><xsl:value-of select="$source-href"/></a>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$source-href"/>
              </xsl:otherwise>
            </xsl:choose>
          </span>
          </div>

          <xsl:if test="xd:input">
            <h3>Input Ports</h3>
            <table border="1">
              <thead>
                <tr>
                  <td>Port</td>
                  <td>Description</td>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates select="xd:input" mode="table-row"/>
              </tbody>
            </table>
          </xsl:if>
          <xsl:if test="xd:output">
            <h3>Output Ports</h3>
            <table border="1">
              <thead>
                <tr>
                  <td>Port</td>
                  <td>Description</td>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates select="xd:output" mode="table-row"/>
              </tbody>
            </table>
          </xsl:if>
          <xsl:if test="xd:option">
            <h3>Options</h3>
            <table border="1">
              <thead>
                <tr>
                  <td class="nowrap">Local Name</td>
                  <td class="nowrap">Namespace URI</td>
                  <td class="nowrap">Default</td>
                  <td>Description</td>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates select="xd:option" mode="table-row"/>
              </tbody>
            </table>
          </xsl:if>

        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="xd:input | xd:output" mode="table-row">
    <tr>
      <td width="150px" class="nowrap name">
        <span class="{if (@primary='true') then 'primary' else ()}"><xsl:value-of select="@port"/></span>

        <span class="details">
          <xsl:if test="@primary='true'">&#160;primary</xsl:if>
          <xsl:choose>
            <xsl:when test="@kind='parameter'">&#160;parameter</xsl:when>
            <xsl:otherwise>
              <xsl:if test="@sequence='true'">&#160;sequence</xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </span>
      </td>

      <td>
        <xsl:apply-templates select="xd:documentation"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xd:option" mode="table-row">
    <tr>
      <td width="150px;" class="nowrap name">
        <span class="{if (@required='true') then 'required' else ()}"><xsl:value-of select="@local-name"/></span>
        <span class="details">
          <xsl:if test="@required='true'">&#160;required</xsl:if>
        </span>
      </td>
      <td width="10px" class="nowrap uri">
        <xsl:value-of select="@namespace-uri"/>
      </td>
      <td width="10px" class="nowrap code">
        <xsl:value-of select="@select"/>
      </td>
      <td>
        <xsl:apply-templates select="xd:documentation"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xd:documentation">
    <xsl:copy-of select="*"/>
  </xsl:template>

  <xsl:template match="xd:documentation" mode="doc-excerpt">
    <xsl:variable name="text-raw"><xsl:value-of select="."/></xsl:variable>
    <xsl:variable name="text-raw-trimmed" select="replace(replace($text-raw,'\s+$',''),'^\s+','')"/>
    <xsl:value-of select="if (string-length($text-raw-trimmed) &gt; 297) then concat(substring($text-raw-trimmed, 0, 297), ' [...]') else $text-raw-trimmed"/>
  </xsl:template>

  <!-- -->

  <xsl:template name="nodelink">
    <xsl:param name="linktext"/>

    <a href="{xd:generate-output-uri(.)}" target="detail"><xsl:copy-of select="$linktext"/></a>
  </xsl:template>

  <!-- -->

  <xsl:function name="xd:step-local-name" as="xs:string">
    <xsl:param name="local-name" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$local-name=''">[untyped]</xsl:when>
      <xsl:otherwise><xsl:value-of select="$local-name"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="xd:step-namespace-uri" as="xs:string">
    <xsl:param name="namespace-uri" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$namespace-uri!=''"><xsl:value-of select="concat('{', $namespace-uri, '}')"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$namespace-uri"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="xd:relativize" as="xs:string">
    <!-- Beware: This is a very naive implementation of URI.relativize() -->
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="base-uri" as="xs:string"/>
    <xsl:variable name="uri-fixed" select="replace(replace($uri, '\\', '/'), '/+', '/')"/>
    <xsl:variable name="base-uri-fixed" select="replace(replace($base-uri, '\\', '/'), '/+', '/')"/>
    <xsl:value-of select="if (starts-with($uri-fixed, $base-uri-fixed)) then substring-after($uri-fixed, $base-uri-fixed) else $uri-fixed"/>
  </xsl:function>

  <xsl:function name="xd:generate-output-uri" as="xs:string">
    <xsl:param name="node"/>
    <xsl:value-of select="concat(generate-id($node),'.html')"/>
  </xsl:function>

  <!-- -->

  <xsl:template name="head">
    <xsl:param name="title"/>
    <head>
      <title><xsl:value-of select="$title"/></title>
      <style type="text/css">
        <![CDATA[
                 table                   { width: 100%; empty-cells: show; }
                 thead                   { background-color: 184882; color: white; font-weight: bold; }
                 td                      { vertical-align: top; padding: 2px; }
                 .name                   { /* font-family: sans-serif; */ }
                 .uri, .code             { font-family: monospace; }
                 .primary, .required     { font-weight: bold; }
                 .details                { display:block; text-align:right; font-size: x-small; font-style: italic; }
                 .nowrap                 { white-space: nowrap; }
                 .small                  { font-size: x-small; }
        ]]>
      </style>
    </head>
  </xsl:template>

</xsl:stylesheet>
