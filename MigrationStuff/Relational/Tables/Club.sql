CREATE TABLE [Relational].[Club] (
    [ClubID]     SMALLINT     NOT NULL,
    [ClubName]   VARCHAR (50) NULL,
    [LiveStatus] BIT          NULL,
    PRIMARY KEY CLUSTERED ([ClubID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Relational].[Club] TO [BIDIMAINReportUser]
    AS [dbo];

