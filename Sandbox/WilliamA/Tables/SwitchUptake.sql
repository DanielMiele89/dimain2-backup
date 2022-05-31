CREATE TABLE [WilliamA].[SwitchUptake] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [memberUId]       NVARCHAR (50) NULL,
    [fanId]           INT           NULL,
    [status]          NVARCHAR (25) NULL,
    [switchFuelType]  NVARCHAR (25) NULL,
    [dual]            BIT           NULL,
    [processed]       BIT           DEFAULT ((0)) NULL,
    [createdDateTime] DATETIME      NULL,
    [updatedDateTime] DATETIME      NULL,
    [matchId]         INT           NULL,
    [transId]         INT           NULL,
    [vectorId]        INT           NULL,
    [vectorMajorId]   INT           NULL,
    [vectorMinorId]   INT           NULL
);


GO
CREATE CLUSTERED INDEX [CIXSU_FANID]
    ON [WilliamA].[SwitchUptake]([fanId] ASC);

