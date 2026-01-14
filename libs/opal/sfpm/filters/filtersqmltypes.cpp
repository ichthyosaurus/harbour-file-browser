// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#include "filter.h"
#include "valuefilter.h"
#include "indexfilter.h"
#include "regexpfilter.h"
#include "rangefilter.h"
#include "expressionfilter.h"
#include "anyoffilter.h"
#include "alloffilter.h"
#include <QQmlEngine>
#include <QCoreApplication>

namespace qqsfpm {

void registerFiltersTypes() {
    qmlRegisterUncreatableType<Filter>("Opal.SortFilterProxyModel", 1, 0, "Filter", "Filter is an abstract class");
    qmlRegisterType<ValueFilter>("Opal.SortFilterProxyModel", 1, 0, "ValueFilter");
    qmlRegisterType<IndexFilter>("Opal.SortFilterProxyModel", 1, 0, "IndexFilter");
    qmlRegisterType<RegExpFilter>("Opal.SortFilterProxyModel", 1, 0, "RegExpFilter");
    qmlRegisterType<RangeFilter>("Opal.SortFilterProxyModel", 1, 0, "RangeFilter");
    qmlRegisterType<ExpressionFilter>("Opal.SortFilterProxyModel", 1, 0, "ExpressionFilter");
    qmlRegisterType<AnyOfFilter>("Opal.SortFilterProxyModel", 1, 0, "AnyOf");
    qmlRegisterType<AllOfFilter>("Opal.SortFilterProxyModel", 1, 0, "AllOf");
    qmlRegisterUncreatableType<FilterContainerAttached>("Opal.SortFilterProxyModel", 1, 0, "FilterContainer", "FilterContainer can only be used as an attaching type");
}

Q_COREAPP_STARTUP_FUNCTION(registerFiltersTypes)

}
