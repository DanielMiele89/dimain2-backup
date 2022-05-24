CREATE TABLE [Prototype].[ROCP2_ActivationVolumes] (
    [ID]                     INT          IDENTITY (1, 1) NOT NULL,
    [ToDate]                 DATE         NULL,
    [Publisher]              VARCHAR (50) NULL,
    [Cumulative_Cardholders] INT          NULL,
    [Added_CardHolders]      INT          NULL
);

