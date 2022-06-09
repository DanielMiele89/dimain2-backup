CREATE TABLE [dbo].[CBP_Credit_ProductType] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [ClientProductCode] NVARCHAR (3) NOT NULL,
    [IssuerID]          INT          NOT NULL,
    [ClubID]            INT          NOT NULL,
    [Name]              VARCHAR (24) NULL
);

