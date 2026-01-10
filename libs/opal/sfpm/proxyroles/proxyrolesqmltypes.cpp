#include "proxyrole.h"
#include "joinrole.h"
#include "switchrole.h"
#include "expressionrole.h"
#include "regexprole.h"
#include "filterrole.h"
#include <QQmlEngine>
#include <QCoreApplication>

namespace qqsfpm {

void registerProxyRoleTypes() {
    qmlRegisterUncreatableType<ProxyRole>("Opal.SortFilterProxyModel", 1, 0, "ProxyRole", "ProxyRole is an abstract class");
    qmlRegisterType<JoinRole>("Opal.SortFilterProxyModel", 1, 0, "JoinRole");
    qmlRegisterType<SwitchRole>("Opal.SortFilterProxyModel", 1, 0, "SwitchRole");
    qmlRegisterType<ExpressionRole>("Opal.SortFilterProxyModel", 1, 0, "ExpressionRole");
    qmlRegisterType<RegExpRole>("Opal.SortFilterProxyModel", 1, 0, "RegExpRole");
    qmlRegisterType<FilterRole>("Opal.SortFilterProxyModel", 1, 0, "FilterRole");
}

Q_COREAPP_STARTUP_FUNCTION(registerProxyRoleTypes)

}
