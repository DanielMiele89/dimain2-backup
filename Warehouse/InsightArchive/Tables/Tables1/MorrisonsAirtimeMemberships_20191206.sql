CREATE TABLE [InsightArchive].[MorrisonsAirtimeMemberships_20191206] (
    [CompositeID]       BIGINT       NOT NULL,
    [IronOfferID]       INT          NOT NULL,
    [ActualStartDate]   DATETIME     NOT NULL,
    [ActualEndDate]     DATETIME     NULL,
    [Date]              DATETIME     NOT NULL,
    [IsControl]         INT          NOT NULL,
    [StartDateForVandC] VARCHAR (10) NOT NULL,
    [EndDateForVandC]   VARCHAR (10) NOT NULL
);

