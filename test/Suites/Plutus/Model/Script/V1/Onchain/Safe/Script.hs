-- | Compiled script for Safe example
module Suites.Plutus.Model.Script.V1.Onchain.Safe.Script (
  Safe,
  safeScript,
) where

import PlutusTx qualified
import Suites.Plutus.Model.Script.V1.Onchain.Safe
import Plutus.Model.V1 (toBuiltinValidator, TypedValidator, mkTypedValidator)

type Safe = TypedValidator SafeDatum SafeAct

-- | The TypedValidator for Safe contract
safeScript :: SafeParams -> Safe
safeScript params = mkTypedValidator (
  $$(PlutusTx.compile [|| \ps -> toBuiltinValidator (safeContract ps) ||])
  `PlutusTx.applyCode` PlutusTx.liftCode params)
