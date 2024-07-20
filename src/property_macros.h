/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*

How to use in QtCreator:

Select "Extras" in the main menu bar, then go to
    Settings -> Text editor -> Snippets -> Group: C++

Select "Add" and add the following snippets:

Name                 Value
RW_PROPERTY          RW_PROPERTY($type$, $name$, $name:c$, $initializer$)
RO_PROPERTY          RO_PROPERTY($type$, $name$, $initializer$)

Name: RW_PROPERTY_CUSTOM
Value:
    RW_PROPERTY_CUSTOM($type$, $name$, $name:c$, $initializer$)
    public slots:
    void set$name:c$(const $type$& newValue) {
        m_$name$ = newValue;
        emit $name$Changed();
    }

Name: RO_PROPERTY_CUSTOM
Value:
    RO_PROPERTY_CUSTOM($type$, $name$, $initializer$)
    public:
    $type$ $name$() const {
        return m_$name$;
    }

*/

// read-write properties
#define RW_PROPERTY(TYPE, R_NAME, W_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME WRITE set##W_NAME NOTIFY R_NAME##Changed) \
    Q_SIGNAL void R_NAME##Changed(); \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: Q_SLOT void set##W_NAME(const TYPE& newValue) { m_##R_NAME = newValue; emit R_NAME##Changed(); } \
    public: TYPE R_NAME() const { return m_##R_NAME; }

// -- with custom setter
#define RW_PROPERTY_CUSTOM(TYPE, R_NAME, W_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME WRITE set##W_NAME NOTIFY R_NAME##Changed) \
    Q_SIGNAL void R_NAME##Changed(); \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: TYPE R_NAME() const { return m_##R_NAME; }
    // public: Q_SLOT void set##W_NAME(const TYPE& newValue) { m_##R_NAME = newValue; emit R_NAME##Changed(); }

// -- without signals for Q_GADGET
#define RW_PROPERTY_GADGET(TYPE, R_NAME, W_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME WRITE set##W_NAME) \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: void set##W_NAME(const TYPE& newValue) { m_##R_NAME = newValue; } \
    public: TYPE R_NAME() const { return m_##R_NAME; }

// -- without signals for Q_GADGET, with custom setter
#define RW_PROPERTY_CUSTOM_GADGET(TYPE, R_NAME, W_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME WRITE set##W_NAME) \
    Q_SIGNAL void R_NAME##Changed(); \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: TYPE R_NAME() const { return m_##R_NAME; }
    // public: void set##W_NAME(const TYPE& newValue) { m_##R_NAME = newValue; }


// read-only properties
#define RO_PROPERTY(TYPE, R_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME NOTIFY R_NAME##Changed) \
    Q_SIGNAL void R_NAME##Changed(); \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: TYPE R_NAME() const { return m_##R_NAME; }

// -- with custom getter
#define RO_PROPERTY_CUSTOM(TYPE, R_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME NOTIFY R_NAME##Changed STORED false) \
    Q_SIGNAL void R_NAME##Changed(); \
    private: TYPE m_##R_NAME {INITIALIZER};
    // public: TYPE R_NAME() const { return m_##R_NAME; }

// -- without signals for Q_GADGET
#define RO_PROPERTY_GADGET(TYPE, R_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME) \
    private: TYPE m_##R_NAME {INITIALIZER}; \
    public: TYPE R_NAME() const { return m_##R_NAME; }

// -- without signals for Q_GADGET, with custom getter
#define RO_PROPERTY_CUSTOM_GADGET(TYPE, R_NAME, INITIALIZER) \
    Q_PROPERTY(TYPE R_NAME READ R_NAME STORED false) \
    private: TYPE m_##R_NAME {INITIALIZER};
    // public: TYPE R_NAME() const { return m_##R_NAME; }
