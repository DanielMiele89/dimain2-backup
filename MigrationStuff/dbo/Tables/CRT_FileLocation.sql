CREATE TABLE [dbo].[CRT_FileLocation] (
    [MatcherShortName]     VARCHAR (12)  NOT NULL,
    [VectorID]             INT           NOT NULL,
    [InboundFileLocation]  VARCHAR (256) NOT NULL,
    [OutboundFileLocation] VARCHAR (256) NOT NULL,
    CONSTRAINT [PK_CRT_FileLocation] PRIMARY KEY CLUSTERED ([MatcherShortName] ASC) WITH (FILLFACTOR = 95)
);

