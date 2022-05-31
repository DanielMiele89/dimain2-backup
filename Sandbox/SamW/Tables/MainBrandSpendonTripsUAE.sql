CREATE TABLE [SamW].[MainBrandSpendonTripsUAE] (
    [CINID]            INT            NOT NULL,
    [Age_Group]        VARCHAR (12)   NULL,
    [Social_Class]     NVARCHAR (255) NULL,
    [Region]           VARCHAR (30)   NULL,
    [Gender]           CHAR (1)       NULL,
    [TripNumber]       BIGINT         NULL,
    [StartTrip]        DATE           NULL,
    [EndTrip]          DATE           NULL,
    [TripLength]       INT            NULL,
    [MainBrandSpender] INT            NULL,
    [BrandName]        VARCHAR (50)   NULL,
    [Sales]            MONEY          NULL,
    [Transactions]     INT            NULL
);

