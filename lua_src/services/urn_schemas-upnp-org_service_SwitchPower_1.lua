-- Returns an IXML document node containing the xml below
return require("upnp").lib.ixml.ParseBuffer( [===[
<?xml version="1.0"?>
<scpd xmlns="urn:schemas-upnp-org:service-1-0">
	<specVersion>
		<major>1</major>
		<minor>0</minor>
	</specVersion>
	<actionList>
		<action>
			<name>SetTarget</name>
			<argumentList>
				<argument>
				<name>newTargetValue</name>
				<relatedStateVariable>Target</relatedStateVariable>
				<direction>in</direction>
				</argument>
			</argumentList>
		</action>
		<action>
			<name>GetTarget</name>
			<argumentList>
				<argument>
					<name>RetTargetValue</name>
					<relatedStateVariable>Target</relatedStateVariable>
					<direction>out</direction>
				</argument>
			</argumentList>
		</action>
		<action>
			<name>GetStatus</name>
			<argumentList>
				<argument>
					<name>ResultStatus</name>
					<relatedStateVariable>Status</relatedStateVariable>
					<direction>out</direction>
				</argument>
			</argumentList>
		</action>
		<!-- Declarations for other actions added by UPnP vendor (if any) go here -->
	</actionList>
	<serviceStateTable>
		<stateVariable sendEvents="no">
			<name>Target</name>
			<dataType>boolean</dataType>
			<defaultValue>0</defaultValue>
		</stateVariable>
		<stateVariable sendEvents="yes">
			<name>Status</name>
			<dataType>boolean</dataType>
			<defaultValue>0</defaultValue>
		</stateVariable>
		<!-- Declarations for other state variables added by UPnP vendor (if any) go here -->
	</serviceStateTable>
</scpd>
]===])
