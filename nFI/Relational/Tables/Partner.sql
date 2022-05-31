CREATE TABLE [Relational].[Partner] (
    [PartnerID]   SMALLINT      NOT NULL,
    [PartnerName] VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Relational].[Partner] TO [BIDIMAINReportUser]
    AS [dbo];


GO
DENY ALTER
    ON OBJECT::[Relational].[Partner] TO [OnCall]
    AS [dbo];


GO
DENY DELETE
    ON OBJECT::[Relational].[Partner] TO [OnCall]
    AS [dbo];

