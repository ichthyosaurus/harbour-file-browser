// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#include "sorter.h"
#include "rolesorter.h"
#include "stringsorter.h"
#include "filtersorter.h"
#include "expressionsorter.h"
#include "sortercontainer.h"
#include <QQmlEngine>
#include <QCoreApplication>

namespace qqsfpm {

void registerSorterTypes() {
    qmlRegisterUncreatableType<Sorter>("Opal.SortFilterProxyModel", 1, 0, "Sorter", "Sorter is an abstract class");
    qmlRegisterType<RoleSorter>("Opal.SortFilterProxyModel", 1, 0, "RoleSorter");
    qmlRegisterType<StringSorter>("Opal.SortFilterProxyModel", 1, 0, "StringSorter");
    qmlRegisterType<FilterSorter>("Opal.SortFilterProxyModel", 1, 0, "FilterSorter");
    qmlRegisterType<ExpressionSorter>("Opal.SortFilterProxyModel", 1, 0, "ExpressionSorter");
    qmlRegisterUncreatableType<SorterContainerAttached>("Opal.SortFilterProxyModel", 1, 0, "SorterContainer", "SorterContainer can only be used as an attaching type");
}

Q_COREAPP_STARTUP_FUNCTION(registerSorterTypes)

}
