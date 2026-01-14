// Copyright (c) 2016 Pierre-Yves Siret
//
// SPDX-License-Identifier: MIT

#include "filtercontainerfilter.h"

namespace qqsfpm {

void FilterContainerFilter::proxyModelCompleted(const QQmlSortFilterProxyModel& proxyModel)
{
    for (Filter* filter : m_filters)
        filter->proxyModelCompleted(proxyModel);
}

void FilterContainerFilter::onFilterAppended(Filter* filter)
{
    connect(filter, &Filter::invalidated, this, &FilterContainerFilter::invalidate);
    invalidate();
}

void FilterContainerFilter::onFilterRemoved(Filter* filter)
{
    Q_UNUSED(filter)
    invalidate();
}

void qqsfpm::FilterContainerFilter::onFiltersCleared()
{
    invalidate();
}

}
