﻿CREATE TABLE [Lion].[BOPEForceIN_ControlGroup_20201008] (
    [FanID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Lion].[BOPEForceIN_ControlGroup_20201008]([FanID] ASC);

