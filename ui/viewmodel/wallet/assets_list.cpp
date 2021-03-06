// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "assets_list.h"
#include "model/app_model.h"

AssetsList::AssetsList()
    : _wallet(*AppModel::getInstance().getWallet())
{
    connect(&_ermgr, &ExchangeRatesManager::rateUnitChanged, this, &AssetsList::onNewRates);
    connect(&_ermgr, &ExchangeRatesManager::activeRateChanged, this, &AssetsList::onNewRates);
    connect(&_wallet, &WalletModel::walletStatusChanged, this, &AssetsList::onWalletStatus);
    connect(&_wallet, &WalletModel::transactionsChanged, this, &AssetsList::onTransactionsChanged);
    connect(&_amgr, &AssetsManager::assetInfo, this, &AssetsList::onAssetInfo);
    _wallet.getAsync()->getTransactions();
}

QHash<int, QByteArray> AssetsList::roleNames() const
{
    static const auto roles = QHash<int, QByteArray>
    {
        {static_cast<int>(Roles::Search),          "search"},
        {static_cast<int>(Roles::RId),             "id"},
        {static_cast<int>(Roles::RUnitName),       "unitName"},
        {static_cast<int>(Roles::RAmount),         "amount"},
        {static_cast<int>(Roles::RInTxCnt),        "inTxCnt"},
        {static_cast<int>(Roles::ROutTxCnt),       "outTxCnt"},
        {static_cast<int>(Roles::RIcon),           "icon"},
        {static_cast<int>(Roles::RColor),          "color"},
        {static_cast<int>(Roles::RSelectionColor), "selectionColor"},
        {static_cast<int>(Roles::RRateUnit),       "rateUnit"},
        {static_cast<int>(Roles::RRate),           "rate"},
    };
    return roles;
}

QVariant AssetsList::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_list.size())
    {
        assert(false);
        return QVariant();
    }

    const auto& asset  = m_list[index.row()];
    const auto assetId = beam::Asset::ID(asset->id());

    switch (static_cast<Roles>(role))
    {
        case Roles::RId:
            return static_cast<qint64>(assetId);
        case Roles::RUnitName:
            return _amgr.getUnitName(assetId);
        case Roles::RAmount:
            return beamui::AmountToUIString(_wallet.getAvailable(assetId));
        case Roles::RInTxCnt:
            return static_cast<qint32>(asset->inTxCnt());
        case Roles::ROutTxCnt:
            return static_cast<qint32>(asset->outTxCnt());
        case Roles::Search:
            return _amgr.getName(assetId) + _amgr.getUnitName(assetId);
        case Roles::RIcon:
            return _amgr.getIcon(assetId);
        case Roles::RColor:
            return _amgr.getColor(assetId);
        case Roles::RSelectionColor:
            return _amgr.getSelectionColor(assetId);
        case Roles::RRateUnit:
            return assetId < 1 ? beamui::getCurrencyUnitName(_ermgr.getRateUnitRaw()) : "";
        case Roles::RRate:
            {
                if (assetId < 1)
                {
                    auto rate = _ermgr.getRate(beam::wallet::ExchangeRate::Currency::Beam);
                    return beamui::AmountToUIString(rate);
                }
                return "";
            }
        default:
            assert(false);
            return QVariant();
    }
}

std::shared_ptr<AssetObject> AssetsList::get(beam::Asset::ID id)
{
     for (auto obj: m_list)
     {
         if (obj->id() == id)
         {
             return obj;
         }
     }
     return std::shared_ptr<AssetObject>();
}

void AssetsList::touch(beam::Asset::ID id)
{
    for (auto it = m_list.begin(); it != m_list.end(); ++it) {
        if ((*it)->id() == id) {
           const auto idx = it - m_list.begin();
           ListModel::touch(idx);
        }
    }
}

void AssetsList::onNewRates()
{
    touch(beam::Asset::s_BeamID);
}

void AssetsList::onWalletStatus()
{
    for(const auto& asset: m_list)
    {
        touch(asset->id());
    }
}

void AssetsList::onAssetInfo(beam::Asset::ID assetId)
{
    touch(assetId);
}

void AssetsList::onTransactionsChanged(beam::wallet::ChangeAction action, const std::vector<beam::wallet::TxDescription>& items)
{
    using namespace beam::wallet;

    TxList modified;

    for (const auto& tx : items)
    {
        if(const auto txType = tx.GetParameter<TxType>(TxParameterID::TransactionType))
        {
            if (txType == TxType::Simple || txType == TxType::PushTransaction)
            {
                modified.push_back(tx);
            }
        }
    }

    switch(action)
    {
    case ChangeAction::Reset:
        _txlist.swap(modified);
        break;

    case ChangeAction::Removed:
        for(auto del: modified)
        {
            _txlist.erase(std::remove_if(_txlist.begin(), _txlist.end(), [&del](const TxDescription& t) {
                return t.m_txId == del.m_txId;
            }), _txlist.end());
        }
        break;

    case ChangeAction::Added:
        _txlist.insert(std::end(_txlist), std::begin(modified), std::end(modified));
        break;

    case ChangeAction::Updated:
        for(auto repl: modified)
        {
            std::replace_if(_txlist.begin(), _txlist.end(), [&repl](const TxDescription& t) {
                return t.m_txId == repl.m_txId;
            }, repl);
        }
        break;

    default:
        assert(false && "Unexpected action");
        break;
    }

    for(auto& obj: m_list) {
        obj->resetTxCnt();
    }

    for(const auto& tx: _txlist) {
        if (auto obj = get(tx.m_assetId))
        {
            if(tx.m_status == wallet::TxStatus::Pending ||
               tx.m_status == wallet::TxStatus::InProgress ||
               tx.m_status == wallet::TxStatus::Registering)
            {
                if (tx.m_sender)
                {
                    obj->addOutTx();
                }
                else
                {
                    obj->addIntTx();
                }
            }
        }
    }

     for(auto& obj: m_list) {
         touch(obj->id());
     }
}
