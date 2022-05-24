CREATE TABLE [Staging].[BrandNewCandidate] (
    [BrandMIDID]      INT          NOT NULL,
    [LocationCountry] VARCHAR (3)  NOT NULL,
    [MID]             VARCHAR (50) NOT NULL,
    [Narrative]       VARCHAR (50) NOT NULL,
    [IsHighVariance]  BIT          NOT NULL,
    [MCC]             VARCHAR (4)  NULL,
    [MCCDesc]         VARCHAR (50) NULL,
    [SectorID]        TINYINT      NULL,
    [MIDFrequency]    INT          NULL,
    PRIMARY KEY CLUSTERED ([BrandMIDID] ASC)
);

