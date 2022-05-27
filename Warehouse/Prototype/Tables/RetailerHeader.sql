CREATE TABLE [Prototype].[RetailerHeader] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [RetailerID] INT           NOT NULL,
    [Header]     VARCHAR (500) COLLATE Latin1_General_CS_AS NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UQ_Prototype_RetailerHeader_Header] UNIQUE NONCLUSTERED ([Header] ASC)
);

