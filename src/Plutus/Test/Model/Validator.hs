{-# Language UndecidableInstances #-}
module Plutus.Test.Model.Validator(
  TypedValidator(..),
  TypedPolicy(..),
  TypedStake(..),
  IsValidator(..),
  Versioned(..),
  mkTypedValidatorV1,
  mkTypedPolicyV1,
  mkTypedStakeV1,
  mkTypedValidatorV2,
  mkTypedPolicyV2,
  mkTypedStakeV2,
  -- utils

  -- * Hashes
  validatorHash,
  scriptCurrencySymbol,
  stakeValidatorHash,
  mintingPolicyHash,
) where

import Prelude
import Data.Kind (Type)
import Cardano.Ledger.Alonzo.Language qualified as C

import PlutusTx.Code (CompiledCode)
import Plutus.V1.Ledger.Api
import Plutus.Test.Model.Blockchain (
  HasAddress(..),
  AppendStaking(..),
  HasStakingCredential(..),
  )
import Plutus.Test.Model.Fork.TxExtra qualified as Fork
import Plutus.Test.Model.Fork.Ledger.Scripts (Versioned(..), toV1, toV2)
import Plutus.Test.Model.Fork.Ledger.Scripts qualified as Fork

class (HasAddress script, ToData (DatumType script), FromData (DatumType script), ToData (RedeemerType script), FromData (RedeemerType script))
  => IsValidator script where
  type DatumType script    :: Type
  type RedeemerType script :: Type
  toValidator :: script -> Validator
  getLanguage :: script -> C.Language

instance (ToData datum, FromData datum, ToData redeemer, FromData redeemer)
  => IsValidator (TypedValidator datum redeemer) where
  type DatumType (TypedValidator datum redeemer) = datum
  type RedeemerType (TypedValidator datum redeemer) = redeemer
  toValidator (TypedValidator (Versioned _lang validator)) = validator
  getLanguage = versioned'language . unTypedValidator

instance (IsValidator script, ToData (DatumType script), FromData (DatumType script), ToData (RedeemerType script), FromData (RedeemerType script))
  => IsValidator (AppendStaking script) where
  type DatumType (AppendStaking script)    = DatumType script
  type RedeemerType (AppendStaking script) = RedeemerType script
  toValidator (AppendStaking _ script) = toValidator script
  getLanguage (AppendStaking _ script) = getLanguage script

instance (ToData redeemer, FromData redeemer) => IsValidator (TypedPolicy redeemer) where
  type DatumType (TypedPolicy redeemer) = ()
  type RedeemerType (TypedPolicy redeemer) = redeemer
  toValidator (TypedPolicy (Versioned _lang (MintingPolicy script))) = Validator script
  getLanguage = versioned'language . unTypedPolicy

validatorHash :: IsValidator a => a -> ValidatorHash
validatorHash v = Fork.validatorHash $ Versioned (getLanguage v) (toValidator v)

-- | Phantom type to annotate types
newtype TypedValidator datum redeemer =
  TypedValidator { unTypedValidator :: (Versioned Validator) }

instance (ToData datum, ToData redeemer, FromData datum, FromData redeemer)
  => HasAddress (TypedValidator datum redeemer) where
  toAddress = toAddress . validatorHash

-- | Phantom type to annotate types
data TypedPolicy redeemer =
  TypedPolicy { unTypedPolicy :: Versioned MintingPolicy }

instance (ToData redeemer, FromData redeemer) => HasAddress (TypedPolicy redeemer) where
  toAddress = toAddress . validatorHash

mkTypedValidatorV1 :: CompiledCode (BuiltinData -> BuiltinData -> BuiltinData -> ()) -> TypedValidator datum redeemer
mkTypedValidatorV1 = TypedValidator . toV1 . mkValidatorScript

mkTypedValidatorV2 :: CompiledCode (BuiltinData -> BuiltinData -> BuiltinData -> ()) -> TypedValidator datum redeemer
mkTypedValidatorV2 = TypedValidator . toV2 . mkValidatorScript

mkTypedPolicyV1 :: CompiledCode (BuiltinData -> BuiltinData -> ()) -> TypedPolicy redeemer
mkTypedPolicyV1 = TypedPolicy . toV1 . mkMintingPolicyScript

mkTypedPolicyV2 :: CompiledCode (BuiltinData -> BuiltinData -> ()) -> TypedPolicy redeemer
mkTypedPolicyV2 = TypedPolicy . toV2 . mkMintingPolicyScript

mkTypedStakeV1 :: CompiledCode (BuiltinData -> BuiltinData -> ()) -> TypedStake redeemer
mkTypedStakeV1 = TypedStake . toV1 . mkStakeValidatorScript

mkTypedStakeV2 :: CompiledCode (BuiltinData -> BuiltinData -> ()) -> TypedStake redeemer
mkTypedStakeV2 = TypedStake . toV2 . mkStakeValidatorScript

newtype TypedStake redeemer =
  TypedStake { unTypedStake :: Versioned StakeValidator }

instance (ToData redeemer, FromData redeemer) => IsValidator (TypedStake redeemer) where
  type DatumType (TypedStake redeemer) = ()
  type RedeemerType (TypedStake redeemer) = redeemer
  toValidator (TypedStake (Versioned _lang (StakeValidator script))) = Validator script
  getLanguage = versioned'language . unTypedStake

instance (ToData redeemer, FromData redeemer) => HasAddress (TypedStake redeemer) where
  toAddress = toAddress . validatorHash

instance HasStakingCredential (TypedStake redeemer) where
  toStakingCredential (TypedStake script) = Fork.scriptToStaking script

---------------------------------------------------------------------------------

scriptCurrencySymbol :: TypedPolicy a -> CurrencySymbol
scriptCurrencySymbol (TypedPolicy script) = Fork.scriptCurrencySymbol script

mintingPolicyHash :: TypedPolicy a -> MintingPolicyHash
mintingPolicyHash (TypedPolicy script) = Fork.mintingPolicyHash script

stakeValidatorHash :: TypedStake a -> StakeValidatorHash
stakeValidatorHash (TypedStake script) = Fork.stakeValidatorHash script

---------------------------------------------------------------------------------

