create TRIGGER [AuditDBDDL]
ON DATABASE
with execute as 'monitor'
FOR 
	DDL_TABLE_EVENTS, 
	DDL_VIEW_EVENTS,
	DDL_FUNCTION_EVENTS, 
	DDL_PROCEDURE_EVENTS, 
	DDL_TRIGGER_EVENTS, 
	DDL_TYPE_EVENTS,
	
	DDL_ASSEMBLY_EVENTS,
	DDL_CERTIFICATE_EVENTS,
	DDL_APPLICATION_ROLE_EVENTS,
	DDL_MASTER_KEY_EVENTS,
	DDL_ROLE_EVENTS,
	DDL_SYMMETRIC_KEY_EVENTS,
	DDL_USER_EVENTS
AS 

SET NOCOUNT ON

declare @event xml

select @event = EVENTDATA()

INSERT Monitor.dbo.DDLLog 
(
	HostName,
	EventType,
	ActionTime,
	LoginName,
	UserName,
	DatabaseName,
	SchemaName,
	ObjectName,
	ObjectType,
	SQLCommand
)
SELECT 
	HOST_NAME(), --HostName
	@event.value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(max)'), --EventType
	@event.value('(/EVENT_INSTANCE/PostTime)[1]','datetime'), --ActionTime
	@event.value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(max)'), --LoginName
	@event.value('(/EVENT_INSTANCE/UserName)[1]','nvarchar(max)'), --UserName
	@event.value('(/EVENT_INSTANCE/DatabaseName)[1]','nvarchar(max)'), --DatabaseName
	case
		when @event.value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(max)') in (
			'ALTER_CERTIFICATE',
			'CREATE_CERTIFICATE',
			'DROP_CERTIFICATE',
			
			'ALTER_SYMMETRIC_KEY',
			'CREATE_SYMMETRIC_KEY',
			'DROP_SYMMETRIC_KEY'
		)
		then 
			@event.value('(/EVENT_INSTANCE/OwnerName)[1]','nvarchar(max)')
		else
			@event.value('(/EVENT_INSTANCE/SchemaName)[1]','nvarchar(max)')
	end, --SchemaName
	@event.value('(/EVENT_INSTANCE/ObjectName)[1]','nvarchar(max)'), --ObjectName
	@event.value('(/EVENT_INSTANCE/ObjectType)[1]','nvarchar(max)'), --ObjectType
	@event.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)') --SQLCommand




GO
DISABLE TRIGGER [AuditDBDDL]
    ON DATABASE;

