"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional
