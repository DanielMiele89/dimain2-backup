CREATE TABLE [Staging].[CustomerInclusions] (
    [ID]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [SourceUID] VARCHAR (100) NULL,
    [PartnerID] INT           NULL,
    [ClubID]    INT           NULL
);

